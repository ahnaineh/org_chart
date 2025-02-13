import 'dart:math';

import 'package:flutter/material.dart';
import 'package:org_chart/src/edge_painter.dart';
import 'package:org_chart/src/custom_animated_positioned.dart';
import 'package:org_chart/src/controller.dart';
import 'package:org_chart/src/node.dart';
import 'package:org_chart/src/node_builder_details.dart';
// export 'controller.dart';

/// This is the widget that the user adds to their build method
class OrgChart<E> extends StatefulWidget {
  /// Minimum graph zoom scale
  final double minScale;

  /// Maximum graph zoom scale
  final double maxScale;

  /// The graph that contains all the data and utility functions that the user can run
  late final OrgChartController<E> controller;

  /// Build the menu that appears when you long press or right click on a node.
  /// Customized per item
  final List<PopupMenuEntry<dynamic>> Function(E item)? optionsBuilder;

  /// The function that is called when you select an option from the menu
  /// inputs the item and the value of the chosen option
  final void Function(E item, dynamic value)? onOptionSelect;

  /// The function that is called when you drop a node on another node
  final void Function(E dragged, E target, bool isTargetSubnode)? onDrop;

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

  /// The style of the arrows: 2 options are available: SolidGraphArrow and DashedGraphArrow
  final GraphArrowStyle arrowStyle;

  /// The builder function used to build the nodes
  final Widget Function(NodeBuilderDetails<E> details) builder;

  OrgChart({
    super.key,
    this.minScale = 0.001,
    this.maxScale = 5.6,
    required this.controller,
    required this.builder,
    this.optionsBuilder,
    this.onOptionSelect,
    this.onDrop,
    this.isDraggable = true,
    this.curve = Curves.elasticOut,
    this.arrowStyle = const SolidGraphArrow(),
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
  List<Node<E>> _overlapping = [];
  String? _draggedID;
  Offset? _panDownPosition;
  final _controller = TransformationController();

  @override
  void initState() {
    widget.controller.setState = setState;
    widget.controller.centerChart = _centerContent;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerContent();
    });

    super.initState();
  }

  void _centerContent() {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final size = renderBox.size;
      final Offset contentSize = widget.controller.getSize();

      final double x = (size.width - contentSize.dx) / 2;
      final double y = (size.height - contentSize.dy) / 2;

      _controller.value = Matrix4.identity()..translate(x, y);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Offset size = widget.controller.getSize();
    return InteractiveViewer(
      constrained: false,
      transformationController: _controller,
      boundaryMargin: const EdgeInsets.all(500),
      minScale: widget.minScale,
      maxScale: widget.maxScale,
      child: SizedBox(
        width: size.dx,
        height: size.dy,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            CustomPaint(
              size: MediaQuery.of(context).size,
              painter: EdgePainter<E>(
                controller: widget.controller,
                linePaint: widget.linePaint,
                arrowStyle: widget.arrowStyle,
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
    List<CustomAnimatedPositioned> widgets = [];
    nodesToDraw ??= widget.controller.roots;

    for (int i = 0; i < nodesToDraw.length; i++) {
      Node<E> node = nodesToDraw[i];

      widgets.add(CustomAnimatedPositioned(
          key: Key("ID: ${widget.controller.idProvider(node.data)}"),
          isBeingDragged: _draggedID == widget.controller.idProvider(node.data),
          curve: widget.curve,
          duration:
              Duration(milliseconds: _draggedID != null ? 0 : widget.duration),
          top: node.position.dy,
          left: node.position.dx,
          child: hidden
              ? const SizedBox.shrink()
              : AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: hidden ? 0 : 1,
                  child: GestureDetector(
                    onTapDown: (TapDownDetails details) {
                      final RenderBox referenceBox =
                          context.findRenderObject() as RenderBox;
                      _panDownPosition =
                          referenceBox.globalToLocal(details.globalPosition);
                    },
                    onLongPress: () async => await _showMenu(context, node),
                    onSecondaryTapDown: (TapDownDetails details) {
                      final RenderBox referenceBox =
                          context.findRenderObject() as RenderBox;
                      _panDownPosition =
                          referenceBox.globalToLocal(details.globalPosition);
                    },
                    onSecondaryTap: () async => await _showMenu(context, node),
                    onPanStart: widget.isDraggable
                        ? (details) {
                            _draggedID =
                                widget.controller.idProvider(node.data);
                          }
                        : null,
                    onPanEnd: widget.isDraggable
                        ? (details) {
                            if (_overlapping.isNotEmpty) {
                              widget.onDrop?.call(
                                  node.data,
                                  _overlapping.first.data,
                                  isSubNode(node, _overlapping.first));
                            }
                            _draggedID = null;
                            _overlapping = [];
                            setState(() {});
                          }
                        : null,
                    onPanUpdate: widget.isDraggable
                        ? (details) {
                            node.position = Offset(
                              max(node.position.dx + details.delta.dx, 0),
                              max(node.position.dy + details.delta.dy, 0),
                            );
                            _overlapping =
                                widget.controller.getOverlapping(node);
                            setState(() {});
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
                            if (hide == node.hideNodes) {
                              return;
                            }
                            setState(() {
                              node.hideNodes = hide ?? !node.hideNodes;
                              widget.controller.calculatePosition();
                            });
                          },
                          nodesHidden: node.hideNodes,
                          isBeingDragged: _draggedID ==
                              widget.controller.idProvider(node.data),
                          isOverlapped: _overlapping.isNotEmpty &&
                              _overlapping.first == node,
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
          Rect.fromLTWH(_panDownPosition!.dx, _panDownPosition!.dy, 30, 30),
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
