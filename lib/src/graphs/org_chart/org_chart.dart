import 'package:flutter/material.dart';
import 'package:org_chart/src/common/custom_animated_positioned.dart';
import 'package:org_chart/src/common/node.dart';
import 'package:org_chart/src/common/node_builder_details.dart';
import 'package:org_chart/src/common/edge_painter.dart';
import 'package:org_chart/src/controllers/org_chart_controller.dart';
import 'package:org_chart/src/graphs/base_graph.dart';
import 'package:org_chart/src/graphs/org_chart/edge_painter.dart';

/// A widget that displays an organizational chart
class OrgChart<E> extends BaseGraph<E> {
  OrgChart({
    Key? key,
    required OrgChartController<E> controller,
    required Widget Function(NodeBuilderDetails<E> details) builder,
    double minScale = 0.001,
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
  OrgChartState<E> createState() => OrgChartState<E>();
}

class OrgChartState<E> extends BaseGraphState<E, OrgChart<E>> {
  late OrgChartEdgePainter<E> _edgePainter;

  @override
  void initState() {
    super.initState();
    _edgePainter = OrgChartEdgePainter<E>(
      chartController: controller,
      linePaint: widget.linePaint,
      arrowStyle: widget.arrowStyle,
      cornerRadius: widget.cornerRadius,
    );
  }

  @override
  List<Widget> buildGraphElements(BuildContext context) {
    return [
      buildEdges(),
      ...buildNodes(context),
    ];
  }

  @override
  Widget buildEdges() {
    return CustomPaint(
      size: Size.infinite,
      painter: _edgePainter,
    );
  }

  @override
  List<Widget> buildNodes(BuildContext context,
      {List<Node<E>>? nodesToDraw, bool hidden = false, int level = 1}) {
    final nodes = nodesToDraw ?? controller.roots;
    final List<Widget> nodeWidgets = [];

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

      if (!node.hideNodes) {
        final subNodes = controller.getSubNodes(node);
        nodeWidgets.addAll(
          buildNodes(
            context,
            nodesToDraw: subNodes,
            level: level + 1,
          ),
        );
      }
    }

    return nodeWidgets;
  }

  @override
  OrgChartController<E> get controller =>
      widget.controller as OrgChartController<E>;
}
