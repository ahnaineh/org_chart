import 'package:flutter/material.dart';
import 'package:org_chart/src/common/custom_animated_positioned.dart';
import 'package:org_chart/src/common/node.dart';
import 'package:org_chart/src/common/node_builder_details.dart';
import 'package:org_chart/src/common/edge_painter.dart';
import 'package:org_chart/src/controllers/genogram_controller.dart';
import 'package:org_chart/src/graphs/base_graph.dart';
import 'package:org_chart/src/graphs/genogram/edge_painter.dart';

/// A widget that displays an organizational chart
class Genogram<E> extends BaseGraph<E> {
  Genogram({
    Key? key,
    required GenogramController<E> controller,
    required Widget Function(NodeBuilderDetails<E> details) builder,
    double minScale = 0.00001,
    double maxScale = 5.6,
    bool isDraggable = true,
    Curve curve = Curves.elasticOut,
    int duration = 700,
    Paint? linePaint,
    double cornerRadius = 10,
    GraphArrowStyle arrowStyle = const SolidGraphArrow(),
    List<PopupMenuEntry<dynamic>> Function(E item)? optionsBuilder,
    void Function(E item, dynamic value)? onOptionSelect,
    void Function(E dragged, E target, bool isTargetSubnode)? onDrop,
  }) : super(
          key: key,
          controller: controller,
          builder: builder,
          minScale: minScale,
          maxScale: maxScale,
          isDraggable: isDraggable,
          curve: curve,
          duration: duration,
          linePaint: linePaint,
          arrowStyle: arrowStyle,
          cornerRadius: cornerRadius,
          optionsBuilder: optionsBuilder,
          onOptionSelect: onOptionSelect,
          onDrop: onDrop,
        );

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
      // widget.onDrop?.call(node.data, overlapping.first.data,
      //     controller.isSubNode(node, overlapping.first));
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
      final String? nodeId = controller.idProvider(node.data);
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
