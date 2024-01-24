library org_chart;

import 'package:flutter/material.dart';
import 'package:org_chart/edge_painter.dart';
import 'package:org_chart/custom_animated_positioned.dart';
import 'package:org_chart/graph.dart';
import 'package:org_chart/node.dart';

export 'graph.dart';

/// The details that are passed to the builder function
/// contains supported properties that can be used to build the node
class NodeBuilderDetails<T> {
  final T item;
  final void Function(bool? hide) hideNodes;
  final bool nodesHidden;
  final bool beingDragged;
  final bool isOverlapped;

  const NodeBuilderDetails({
    required this.item,
    required this.hideNodes,
    required this.beingDragged,
    required this.isOverlapped,
    required this.nodesHidden,
  });
}

/// This is the widget that the user adds to their build method
class OrgChart<E> extends StatefulWidget {
  /// The graph that contains all the data and utility functions that the user can run
  final Graph<E> graph;

  /// optionsbuilder to build the menu that appears when you long press or right click on a node
  /// can be customized per item
  final List<PopupMenuEntry<dynamic>> Function(E node)? optionsBuilder;

  /// The function that is called when you select an option from the menu
  /// inputs the item and the value of the chosen option
  final void Function(E item, dynamic value)? onOptionSelect;

  /// The function that is called when you drop a node on another node
  final void Function(E dragged, E target)? onDrop;

  /// Whether to allow dragging nodes or not
  final bool isDraggable;

  /// The curve that is used when animating the nodes back to their position
  final Curve curve;

  /// The duration, in milliseconds, of the animation when animating the nodes back to their position
  final int duration;

  final Widget Function(NodeBuilderDetails<E> details) builder;

  const OrgChart({
    super.key,
    required this.graph,
    required this.builder,
    this.optionsBuilder,
    this.onOptionSelect,
    this.onDrop,
    this.isDraggable = true,
    this.curve = Curves.elasticOut,
    this.duration = 700,
  });

  @override
  State<OrgChart<E>> createState() => _OrgChartState();
}

class _OrgChartState<E> extends State<OrgChart<E>> {
  List<Node<E>> overlapping = [];
  String? draggedID;
  Offset? panDownPosition;

  @override
  Widget build(BuildContext context) {
    Offset size = widget.graph.getSize();
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
              painter: EdgePainter<E>(graph: widget.graph),
            ),
            ...draw(context)..sort((a, b) => a.isBeingDragged ? 1 : -1),
          ],
        ),
      ),
    );
  }

  List<CustomAnimatedPositioned> draw(context,
      {List<Node<E>>? nodesToDraw, bool hidden = false}) {
    nodesToDraw ??= widget.graph.roots;
    List<CustomAnimatedPositioned> widgets = [];

    for (int i = 0; i < nodesToDraw.length; i++) {
      Node<E> node = nodesToDraw[i];
      widgets.add(CustomAnimatedPositioned(
          key: Key("ID: ${widget.graph.idProvider(node.data)}"),
          isBeingDragged: draggedID == widget.graph.idProvider(node.data),
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
                            widget.graph.changeNodeIndex(node, -1);

                            draggedID = widget.graph.idProvider(node.data);
                          }
                        : null,
                    onPanEnd: widget.isDraggable
                        ? (details) {
                            if (overlapping.isNotEmpty) {
                              widget.onDrop
                                  ?.call(node.data, overlapping.first.data);
                            }
                            draggedID = null;
                            overlapping = [];
                            setState(() {});
                          }
                        : null,
                    onPanUpdate: widget.isDraggable
                        ? (details) {
                            overlapping = widget.graph.getOverlapping(node);

                            setState(() => node.position += details.delta);
                          }
                        : null,
                    child: SizedBox(
                      height: widget.graph.boxSize.height,
                      width: widget.graph.boxSize.width,
                      child: widget.builder(
                        NodeBuilderDetails<E>(
                          item: node.data,
                          hideNodes: (hide) {
                            setState(() {
                              node.hideNodes = hide ?? !node.hideNodes;
                              widget.graph.calculatePosition();
                            });
                          },
                          nodesHidden: node.hideNodes,
                          beingDragged:
                              draggedID == widget.graph.idProvider(node.data),
                          isOverlapped: overlapping.isNotEmpty &&
                              overlapping.first == node,
                        ),
                      ),
                    ),
                  ),
                )));
      widgets.addAll(draw(context,
          nodesToDraw: widget.graph.getSubNodes(node).toList(),
          hidden: node.hideNodes || hidden));
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
}
