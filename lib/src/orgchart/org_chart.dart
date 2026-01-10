import 'package:flutter/material.dart';
import 'package:org_chart/src/common/node.dart';
import 'package:org_chart/src/common/node_builder_details.dart';
import 'package:org_chart/src/orgchart/org_chart_controller.dart';
import 'package:org_chart/src/base/base_graph.dart';
import 'package:org_chart/src/orgchart/edge_painter.dart';
import 'package:org_chart/src/common/edge_label_layer.dart';
import 'package:org_chart/src/rendering/graph_render_widget.dart';

/// A widget that displays an organizational chart
class OrgChart<E> extends BaseGraph<E> {
  final void Function(E dragged, E target, bool isTargetSubnode)? onDrop;

  OrgChart({
    super.key,
    required OrgChartController<E> super.controller,
    required super.builder,
    super.isDraggable,
    super.curve,
    super.duration,
    super.linePaint,
    super.cornerRadius,
    super.arrowStyle,
    super.lineEndingType,
    super.edgeStyleProvider,
    super.edgeLabelBuilder,
    super.edgeLabelConfig,
    super.optionsBuilder,
    super.onOptionSelect,
    super.viewerController,
    super.interactionConfig,
    super.keyboardConfig,
    super.zoomConfig,
    super.focusNode,
    this.onDrop,
  });

  @override
  OrgChartState<E> createState() => OrgChartState<E>();
}

class OrgChartState<E> extends BaseGraphState<E, OrgChart<E>> {
  late OrgChartEdgePainter<E> _edgePainter;
  TextDirection _textDirection = TextDirection.ltr;

  @override
  void initState() {
    super.initState();
    _edgePainter = _createEdgePainter();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final TextDirection direction = Directionality.of(context);
    if (_textDirection != direction) {
      _textDirection = direction;
      _edgePainter = _createEdgePainter();
    }
  }

  @override
  void didUpdateWidget(covariant OrgChart<E> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _edgePainter = _createEdgePainter();
  }

  OrgChartEdgePainter<E> _createEdgePainter() {
    return OrgChartEdgePainter<E>(
      controller: controller,
      linePaint: widget.linePaint,
      arrowStyle: widget.arrowStyle,
      cornerRadius: widget.cornerRadius,
      lineEndingType: widget.lineEndingType,
      edgeStyleProvider: widget.edgeStyleProvider,
      textDirection: _textDirection,
    );
  }

  @override
  List<Widget> buildGraphElements(BuildContext context) {
    final Size graphSize = controller.getSize();
    return [
      buildEdges(),
      buildEdgeLabels(),
      SizedBox(
        width: graphSize.width,
        height: graphSize.height,
        child: GraphRenderWidget(
          children: buildNodes(context),
        ),
      ),
    ];
  }

  void finishDragging(Node<E> node) {
    // Do a final overlap check
    overlapping = widget.controller.getOverlapping(node);

    if (overlapping.isNotEmpty) {
      widget.onDrop?.call(node.data, overlapping.first.data,
          controller.isSubNode(node, overlapping.first));
    }
    draggedID = null;
    overlapping = [];
    lastDraggedNode = null;
    setState(() {});
  }

  @override
  Widget buildEdges() {
    return CustomPaint(
      size: controller.getSize(),
      painter: _edgePainter,
    );
  }

  Widget buildEdgeLabels() {
    if (widget.edgeLabelBuilder == null) {
      return const SizedBox.shrink();
    }

    final Size graphSize = controller.getSize();
    return SizedBox(
      width: graphSize.width,
      height: graphSize.height,
      child: EdgeLabelLayer<E>(
        edges: _edgePainter.buildEdges(),
        labelBuilder: widget.edgeLabelBuilder!,
        config: widget.edgeLabelConfig,
        graphSize: graphSize,
        edgeStyleProvider: widget.edgeStyleProvider,
      ),
    );
  }

  @override
  List<AnimatedGraphChild> buildNodes(BuildContext context,
      {List<Node<E>>? nodesToDraw, bool hidden = false, int level = 1}) {
    final List<AnimatedGraphChild> normalNodes = [];
    final List<AnimatedGraphChild> draggedNodes = [];

    void visit(List<Node<E>> nodes, int currentLevel) {
      for (final Node<E> node in nodes) {
        final String nodeId = controller.idProvider(node.data);
        final bool isBeingDragged = nodeId == draggedID;

        final AnimatedGraphChild positioned = AnimatedGraphChild(
          key: ValueKey(nodeId),
          nodeId: nodeId,
          offset: node.position,
          duration: isBeingDragged ? Duration.zero : widget.duration,
          curve: widget.curve,
          child: SizedBox(
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
                  onSecondaryTap: () => showNodeMenu(context, node),
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
                      level: currentLevel,
                      hideNodes: ({hide, center = true}) =>
                          toggleHideNodes(node, hide, center),
                      nodesHidden: node.hideNodes,
                      isBeingDragged: isBeingDragged,
                      isOverlapped: overlappingNodes.isNotEmpty &&
                          overlappingNodes.first.data == node.data,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        if (isBeingDragged) {
          draggedNodes.add(positioned);
        } else {
          normalNodes.add(positioned);
        }

        if (!node.hideNodes) {
          visit(controller.getSubNodes(node), currentLevel + 1);
        }
      }
    }

    visit(nodesToDraw ?? controller.roots, level);
    return [...normalNodes, ...draggedNodes];
  }

  @override
  OrgChartController<E> get controller =>
      widget.controller as OrgChartController<E>;
}
