import 'package:flutter/material.dart';
import 'package:org_chart/src/common/custom_animated_positioned.dart';
import 'package:org_chart/src/common/node.dart';
import 'package:org_chart/src/common/node_builder_details.dart';
import 'package:org_chart/src/controllers/genogram_controller.dart';
import 'package:org_chart/src/graphs/base_graph.dart';
import 'package:org_chart/src/graphs/genogram/edge_painter.dart';

/// A widget that displays an organizational chart
class Genogram<E> extends BaseGraph<E> {

  final void Function(E dragged, E target)? onDrop;
  
  Genogram({
    super.key,
    required GenogramController<E> super.controller,
    required super.builder,
    super.minScale = 0.00001,
    super.maxScale,
    super.isDraggable,
    super.curve,
    super.duration,
    super.linePaint,
    super.cornerRadius,
    super.arrowStyle,
    super.optionsBuilder,
    super.onOptionSelect,
    this.onDrop,
  });

  @override
  GenogramState<E> createState() => GenogramState<E>();
}

class GenogramState<E> extends BaseGraphState<E, Genogram<E>> {
  late GenogramEdgePainter<E> _edgePainter;

  @override
  void initState() {
    super.initState();
    _edgePainter = GenogramEdgePainter<E>(
      controller: controller,
      linePaint: widget.linePaint,
      arrowStyle: widget.arrowStyle,
      cornerRadius: widget.cornerRadius,
    );
  }

  @override
  List<Widget> buildGraphElements(BuildContext context) {
    return [
      buildEdges(),
      ...buildNodes(context)..sort((a, b) => a.isBeingDragged ? 1 : -1),
    ];
  }

  void finishDragging(Node<E> node) {
    if (overlapping.isNotEmpty) {
        widget.onDrop?.call(node.data, overlapping.first.data);
    }
    draggedID = null;
    overlapping = [];
    setState(() {});
  }

  @override
  Widget buildEdges() {
    return CustomPaint(
      painter: _edgePainter,
    );
  }

  @override
  List<CustomAnimatedPositioned> buildNodes(BuildContext context,
      {List<Node<E>>? nodesToDraw, bool hidden = false, int level = 1}) {
    final nodes = nodesToDraw ?? controller.nodes;
    final List<CustomAnimatedPositioned> nodeWidgets = [];

    for (Node<E> node in nodes) {
      final String nodeId = controller.idProvider(node.data);
      nodeWidgets.add(
        CustomAnimatedPositioned(
          key: ValueKey(nodeId),
          isBeingDragged: nodeId == draggedID,
          duration:
              Duration(milliseconds: nodeId == draggedID ? 0 : widget.duration),
          curve: widget.curve,
          left: node.position.dx,
          top: node.position.dy,
          width: controller.boxSize.width,
          height: controller.boxSize.height,
          child: Visibility(
            visible: !hidden,
            maintainAnimation: true,
            maintainSize: true,
            maintainState: true,
            child: GestureDetector(
              onTapDown: handleTapDown,
              onLongPress: () => showNodeMenu(context, node),
              onPanStart:
                  widget.isDraggable ? (_) => startDragging(node) : null,
              onPanUpdate: widget.isDraggable
                  ? (details) => updateDragging(node, details)
                  : null,
              onPanEnd: widget.isDraggable ? (_) => finishDragging(node) : null,
              child: widget.builder(
                NodeBuilderDetails(
                  item: node.data,
                  level: level,
                  hideNodes: (hide) => toggleHideNodes(node, hide),
                  nodesHidden: node.hideNodes,
                  isBeingDragged: nodeId == draggedID,
                  isOverlapped: overlappingNodes.isNotEmpty &&
                      overlappingNodes.first.data == node.data,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return nodeWidgets;
  }

  @override
  GenogramController<E> get controller =>
      widget.controller as GenogramController<E>;
}
