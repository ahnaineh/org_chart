library org_chart;

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:org_chart/edge_painter.dart';
import 'package:org_chart/custom_animated_positioned.dart';
import 'package:org_chart/graph.dart';
import 'package:org_chart/node.dart';

class OrgChart<E> extends StatefulWidget {
  final Graph<E> graph;
  final List<PopupMenuEntry<dynamic>> Function(Node<E> node)? optionsBuilder;
  final void Function(E item, dynamic value)? onOptionSelect;
  final void Function(E dragged, E target)? onDrop;
  final bool isDraggable;
  
  
  final Widget Function(
    Node<E> node,
    bool beingDragged,
    bool isOverlapped,
  ) builder;
  
  const OrgChart({
    super.key,
    required this.graph,
    required this.builder,
    this.optionsBuilder,
    this.onOptionSelect,
    this.onDrop,
    this.isDraggable = true,
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
          curve: Curves.elasticOut,
          duration: Duration(milliseconds: draggedID != null ? 0 : 700),
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
                            overlapping.sort((a, b) =>
                                _distance(a.position, node.position).compareTo(
                                    _distance(b.position, node.position)));
                            setState(() => node.position += details.delta);
                          }
                        : null,
                    child: SizedBox(
                      height: widget.graph.boxSize.height,
                      width: widget.graph.boxSize.width,
                      child: widget.builder(
                        node,
                        draggedID == widget.graph.idProvider(node.data),
                        overlapping.isNotEmpty && overlapping.first == node,
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

  double _distance(Offset a, Offset b) {
    return math.sqrt(math.pow(a.dx - b.dx, 2) + math.pow(a.dy - b.dy, 2));
  }


  _showMenu(context, node) async {
    List<PopupMenuEntry<dynamic>> options =
        widget.optionsBuilder?.call(node) ?? [];
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

    widget.onOptionSelect?.call(node, result);
  }

}
