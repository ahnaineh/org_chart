import 'package:flutter/material.dart';
import 'package:org_chart/src/genogram/genogram_enums.dart';
import 'package:org_chart/src/common/node.dart';
import 'package:org_chart/src/common/node_builder_details.dart';
import 'package:org_chart/src/genogram/genogram_controller.dart';
import 'package:org_chart/src/base/base_graph.dart';
import 'package:org_chart/src/base/graph_layout.dart';
import 'package:org_chart/src/genogram/edge_painter.dart';
import 'package:org_chart/src/genogram/genogram_edge_config.dart';
import 'package:org_chart/src/common/edge_label_layer.dart';

/// A widget that displays an organizational chart
class Genogram<E> extends BaseGraph<E> {
  final void Function(E dragged, E target)? onDrop;

  /// Configuration for edge painter styling
  final GenogramEdgeConfig edgeConfig;

  /// Function to determine marriage status between two people
  final MarriageStatus Function(E person, E spouse)? marriageStatusProvider;

  Genogram({
    super.key,
    required super.controller,
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
    this.edgeConfig = const GenogramEdgeConfig(),
    this.marriageStatusProvider,
    this.onDrop,
  });

  @override
  GenogramState<E> createState() => GenogramState<E>();
}

class GenogramState<E> extends BaseGraphState<E, Genogram<E>> {
  late GenogramEdgePainter<E> _edgePainter;
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
  void didUpdateWidget(covariant Genogram<E> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _edgePainter = _createEdgePainter();
  }

  GenogramEdgePainter<E> _createEdgePainter() {
    return GenogramEdgePainter<E>(
      controller: controller,
      linePaint: widget.linePaint,
      arrowStyle: widget.arrowStyle,
      cornerRadius: widget.cornerRadius,
      lineEndingType: widget.lineEndingType,
      config: widget.edgeConfig,
      marriageStatusProvider: widget.marriageStatusProvider,
      edgeStyleProvider: widget.edgeStyleProvider,
      textDirection: _textDirection,
      repaint: edgeRepaintListenable,
    );
  }

  @override
  List<Widget> buildGraphElements(BuildContext context) {
    final List<Widget> nodeWidgets = buildNodes(context);
    nodeWidgets.sort((a, b) {
      final bool aDragged =
          a is GraphNode<E> ? a.isBeingDragged : false;
      final bool bDragged =
          b is GraphNode<E> ? b.isBeingDragged : false;
      if (aDragged == bDragged) return 0;
      return aDragged ? 1 : -1;
    });
    return [
      buildEdges(),
      buildEdgeLabels(),
      GraphLayout<E>(
        key: graphLayoutKey,
        controller: controller,
        animationController: layoutAnimationController,
        curve: widget.curve,
        textDirection: _textDirection,
        children: nodeWidgets,
      ),
    ];
  }

  void finishDragging(Node<E> node) {
    // Do a final overlap check
    overlapping = widget.controller.getOverlapping(node);

    if (overlapping.isNotEmpty) {
      widget.onDrop?.call(node.data, overlapping.first.data);
    }
    draggedID = null;
    widget.controller.draggedNodeId = null;
    overlapping = [];
    lastDraggedNode = null;
    notifyEdgeRepaint();
    setState(() {});
  }

  @override
  Widget buildEdges() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _edgePainter,
      ),
    );
  }

  Widget buildEdgeLabels() {
    if (widget.edgeLabelBuilder == null) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: edgeRepaintListenable,
        builder: (context, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final Size graphSize = Size(
                constraints.maxWidth,
                constraints.maxHeight,
              );
              return EdgeLabelLayer<E>(
                edges: _edgePainter.buildEdges(graphSize),
                labelBuilder: widget.edgeLabelBuilder!,
                config: widget.edgeLabelConfig,
                graphSize: graphSize,
                edgeStyleProvider: widget.edgeStyleProvider,
              );
            },
          );
        },
      ),
    );
  }

  @override
  List<Widget> buildNodes(BuildContext context,
      {List<Node<E>>? nodesToDraw, bool hidden = false, int level = 1}) {
    final nodes = nodesToDraw ?? controller.nodes;
    final List<Widget> nodeWidgets = [];

    for (Node<E> node in nodes) {
      final String nodeId = controller.idProvider(node.data);

      nodeWidgets.add(
        GraphNode<E>(
          key: ValueKey(nodeId),
          node: node,
          isBeingDragged: nodeId == draggedID,
          child: RepaintBoundary(
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
    }

    return nodeWidgets;
  }

  @override
  GenogramController<E> get controller =>
      widget.controller as GenogramController<E>;
}
