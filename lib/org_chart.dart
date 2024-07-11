library org_chart;

import 'package:flutter/material.dart';
import 'package:org_chart/edge_painter.dart';
import 'package:org_chart/custom_animated_positioned.dart';
import 'package:org_chart/controller.dart';
import 'package:org_chart/node.dart';

export 'controller.dart';

/// The details that are passed to the builder function
/// contains supported properties that can be used to build the node
class NodeBuilderDetails<T> {
  final T item;
  final int level;
  final void Function(bool? hide) hideNodes;
  final bool nodesHidden;
  final bool isBeingDragged;
  final bool isOverlapped;

  const NodeBuilderDetails({
    required this.item,
    required this.level,
    required this.hideNodes,
    required this.isBeingDragged,
    required this.isOverlapped,
    required this.nodesHidden,
  });
}

/// This is the widget that the user adds to their build method
class OrgChart<E> extends StatefulWidget {
  /// The graph that contains all the data and utility functions that the user can run
  late final OrgChartController<E> controller;

  /// optionsbuilder to build the menu that appears when you long press or right click on a node
  /// can be customized per item
  final List<PopupMenuEntry<dynamic>> Function(E node)? optionsBuilder;

  /// The function that is called when you select an option from the menu
  /// inputs the item and the value of the chosen option
  final void Function(E item, dynamic value)? onOptionSelect;

  /// The function that is called when you drop a node on another node
  final void Function(E dragged, E target, bool isTargetSubnode)? onDrop;

  /// The function that is called when you tap on a node
  final void Function(E item)? onTap;

  /// The function that is called when you double tap on a node
  final void Function(E item)? onDoubleTap;

  /// Whether to allow dragging nodes or not
  final bool isDraggable;

  /// The curve that is used when animating the nodes back to their position
  final Curve curve;

  /// The duration, in milliseconds, of the animation when animating the nodes back to their position
  final int duration;

  /// The paint to draw the arrows with
  late final Paint linePaint;

  /// The radius of the corner in the arrows
  final double cornerRadius;

  /// The builder function used to build the nodes
  final Widget Function(NodeBuilderDetails<E> details) builder;

  OrgChart({
    super.key,
    required this.controller,
    required this.builder,
    this.optionsBuilder,
    this.onOptionSelect,
    this.onDrop,
    this.isDraggable = true,
    this.onTap,
    this.onDoubleTap,
    this.curve = Curves.elasticOut,
    this.duration = 700,
    Paint? linePaint,
    this.cornerRadius = 10.0,
  }) {
    if (linePaint != null) {
      this.linePaint = linePaint;
    } else {
      this.linePaint = Paint()
        ..color = Colors.black
        ..strokeWidth = 0.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
    }
  }

  @override
  State<OrgChart<E>> createState() => _OrgChartState();
}

class _OrgChartState<E> extends State<OrgChart<E>> {
  List<Node<E>> overlapping = [];
  String? draggedID;
  Offset? panDownPosition;

  @override
  void initState() {
    widget.controller.setState = setState;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Offset size = widget.controller.getSize();
    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(1000),
      minScale: 0.001,
      maxScale: 5.6,
      child: SizedBox(
        width: size.dx + 100,
        height: size.dy + 100,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            CustomPaint(
              size: MediaQuery.of(context).size,
              painter: EdgePainter<E>(
                controller: widget.controller,
                linePaint: widget.linePaint,
                cornerRadius: widget.cornerRadius,
              ),
            ),
            ...draw(context)..sort((a, b) => a.isBeingDragged ? 1 : -1),
          ],
        ),
      ),
    );
  }

  List<CustomAnimatedPositioned> draw(context,
      {List<Node<E>>? nodesToDraw, bool hidden = false, int level = 1}) {
    nodesToDraw ??= widget.controller.roots;
    List<CustomAnimatedPositioned> widgets = [];

    for (int i = 0; i < nodesToDraw.length; i++) {
      Node<E> node = nodesToDraw[i];
      widgets.add(CustomAnimatedPositioned(
          key: Key("ID: ${widget.controller.idProvider(node.data)}"),
          isBeingDragged: draggedID == widget.controller.idProvider(node.data),
          curve: widget.curve,
          duration:
              Duration(milliseconds: draggedID != null ? 0 : widget.duration),
          top: node.position.dy,
          left: node.position.dx,
          child: hidden
              ? const SizedBox.shrink()
              : AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: hidden ? 0 : 1,
                  child: GestureDetector(
                    onTap: () => widget.onTap?.call(node.data),
                    onDoubleTap: () => widget.onDoubleTap?.call(node.data),
                    onTapDown: (TapDownDetails details) {
                      final RenderBox referenceBox =
                          context.findRenderObject() as RenderBox;
                      panDownPosition =
                          referenceBox.globalToLocal(details.globalPosition);
                    },
                    onLongPress: () async => await _showMenu(context, node),
                    onSecondaryTapDown: (TapDownDetails details) {
                      final RenderBox referenceBox =
                          context.findRenderObject() as RenderBox;
                      panDownPosition =
                          referenceBox.globalToLocal(details.globalPosition);
                    },
                    onSecondaryTap: () async => await _showMenu(context, node),
                    onPanStart: widget.isDraggable
                        ? (details) {
                            widget.controller.changeNodeIndex(node, -1);

                            draggedID = widget.controller.idProvider(node.data);
                          }
                        : null,
                    onPanEnd: widget.isDraggable
                        ? (details) {
                            if (overlapping.isNotEmpty) {
                              widget.onDrop?.call(
                                  node.data,
                                  overlapping.first.data,
                                  isSubNode(node, overlapping.first));
                            }
                            draggedID = null;
                            overlapping = [];
                            setState(() {});
                          }
                        : null,
                    onPanUpdate: widget.isDraggable
                        ? (details) {
                            overlapping =
                                widget.controller.getOverlapping(node);

                            setState(() => node.position += details.delta);
                          }
                        : null,
                    child: SizedBox(
                      height: widget.controller.boxSize.height,
                      width: widget.controller.boxSize.width,
                      child: widget.builder(
                        NodeBuilderDetails<E>(
                          item: node.data,
                          level: level,
                          hideNodes: (hide) {
                            setState(() {
                              node.hideNodes = hide ?? !node.hideNodes;
                              widget.controller.calculatePosition();
                            });
                          },
                          nodesHidden: node.hideNodes,
                          isBeingDragged: draggedID ==
                              widget.controller.idProvider(node.data),
                          isOverlapped: overlapping.isNotEmpty &&
                              overlapping.first == node,
                        ),
                      ),
                    ),
                  ),
                )));
      widgets.addAll(
        draw(
          context,
          nodesToDraw: widget.controller.getSubNodes(node).toList(),
          hidden: node.hideNodes || hidden,
          level: level + 1,
        ),
      );
    }
    return widgets;
  }

  _showMenu(context, node) async {
    List<PopupMenuEntry<dynamic>> options =
        widget.optionsBuilder?.call(node.data) ?? [];
    if (options.isEmpty) return;
    final RenderObject? overlay =
        Overlay.of(context).context.findRenderObject();

    final result = await showMenu(
      context: context,
      position: RelativeRect.fromRect(
          Rect.fromLTWH(panDownPosition!.dx, panDownPosition!.dy, 30, 30),
          Rect.fromLTWH(0, 0, overlay!.paintBounds.size.width,
              overlay.paintBounds.size.height)),
      items: options,
    );

    widget.onOptionSelect?.call(node.data, result);
  }

  bool isSubNode(Node<E> dragged, Node<E> target) {
    E? to = target.data;
    dynamic draggedId = widget.controller.idProvider(dragged.data);
    while (to != null) {
      dynamic toId = widget.controller.toProvider(to);
      if (toId == draggedId) {
        return true;
      }
      to = widget.controller.items
          .where((element) => widget.controller.idProvider(element) == toId)
          .firstOrNull;
    }
    return false;
  }
}
