import 'package:flutter/material.dart';
import 'package:org_chart/src/common/custom_animated_positioned.dart';
import 'package:org_chart/src/common/node.dart';
import 'package:org_chart/src/common/node_builder_details.dart';
import 'package:org_chart/src/orgchart/org_chart_controller.dart';
import 'package:org_chart/src/base/base_graph.dart';
import 'package:org_chart/src/orgchart/edge_painter.dart';

/// A widget that displays an organizational chart
class OrgChart<E> extends BaseGraph<E> {
  final void Function(E dragged, E target, bool isTargetSubnode)? onDrop;

  OrgChart({
    super.key,
    required OrgChartController<E> super.controller,
    required super.builder,
    super.minScale,
    super.maxScale,
    super.isDraggable,
    super.curve,
    super.duration,
    super.linePaint,
    super.cornerRadius,
    super.arrowStyle,
    super.optionsBuilder,
    super.onOptionSelect,
    super.viewerController,
    super.enableZoom,
    super.enableRotation,
    super.constrainBounds,
    super.enableDoubleTapZoom,
    super.doubleTapZoomFactor,
    super.enableKeyboardControls,
    super.keyboardPanDistance,
    super.keyboardZoomFactor,
    super.enableKeyRepeat,
    super.keyRepeatInitialDelay,
    super.keyRepeatInterval,
    super.enableCtrlScrollToScale,
    super.enableFling,
    super.enablePan,
    super.focusNode,
    super.animateKeyboardTransitions,
    super.keyboardAnimationCurve,
    super.keyboardAnimationDuration,
    super.invertArrowKeyDirection,
    this.onDrop,
  });

  @override
  OrgChartState<E> createState() => OrgChartState<E>();
}

class OrgChartState<E> extends BaseGraphState<E, OrgChart<E>> {
  late OrgChartEdgePainter<E> _edgePainter;

  @override
  void initState() {
    super.initState();
    _edgePainter = OrgChartEdgePainter<E>(
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
      widget.onDrop?.call(node.data, overlapping.first.data,
          controller.isSubNode(node, overlapping.first));
    }
    draggedID = null;
    overlapping = [];
    setState(() {});
  }

  @override
  Widget buildEdges() {
    return CustomPaint(
      painter: _edgePainter,
      child: SizedBox.shrink(),
    );
  }

  @override
  List<CustomAnimatedPositioned> buildNodes(BuildContext context,
      {List<Node<E>>? nodesToDraw, bool hidden = false, int level = 1}) {
    final nodes = nodesToDraw ?? controller.roots;
    final List<CustomAnimatedPositioned> nodeWidgets = [];

    for (Node<E> node in nodes) {
      final String nodeId = controller.idProvider(node.data);

      nodeWidgets.add(
        CustomAnimatedPositioned(
          key: ValueKey(nodeId),
          isBeingDragged: nodeId == draggedID,
          duration: nodeId == draggedID ? Duration.zero : widget.duration,
          curve: widget.curve,
          left: node.position.dx,
          top: node.position.dy,
          width: controller.boxSize.width,
          height: controller.boxSize.height,
          child: RepaintBoundary(
            child: Visibility(
              visible: !hidden,
              maintainAnimation: true,
              maintainSize: true,
              maintainState: true,
              child: GestureDetector(
                onTapDown: handleTapDown,
                // TODO: Implement onSecondaryTap
                // onSecondaryTap: () => showNodeMenu(context, node),
                onLongPress: () => showNodeMenu(context, node),
                onPanStart:
                    widget.isDraggable ? (_) => startDragging(node) : null,
                onPanUpdate: widget.isDraggable
                    ? (details) => updateDragging(node, details)
                    : null,
                onPanEnd:
                    widget.isDraggable ? (_) => finishDragging(node) : null,
                child: widget.builder(
                  NodeBuilderDetails(
                    item: node.data,
                    level: level,
                    hideNodes: ({hide, center = true}) =>
                        toggleHideNodes(node, hide, center),
                    nodesHidden: node.hideNodes,
                    isBeingDragged: nodeId == draggedID,
                    isOverlapped: overlappingNodes.isNotEmpty &&
                        overlappingNodes.first.data == node.data,
                  ),
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
