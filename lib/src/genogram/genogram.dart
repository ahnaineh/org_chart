import 'package:flutter/material.dart';
import 'package:org_chart/src/common/custom_animated_positioned.dart';
import 'package:org_chart/src/genogram/genogram_enums.dart';
import 'package:org_chart/src/common/node.dart';
import 'package:org_chart/src/common/node_builder_details.dart';
import 'package:org_chart/src/genogram/genogram_controller.dart';
import 'package:org_chart/src/base/base_graph.dart';
import 'package:org_chart/src/genogram/edge_painter.dart';
import 'package:org_chart/src/genogram/genogram_edge_config.dart';

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
    // required GenogramController<E> super.controller,
    required super.builder,
    super.isDraggable,
    super.curve,
    super.duration,
    super.linePaint,
    super.cornerRadius,
    super.arrowStyle,
    super.lineEndingType,
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
  @override
  void initState() {
    super.initState();
    _edgePainter = GenogramEdgePainter<E>(
      controller: controller,
      linePaint: widget.linePaint,
      arrowStyle: widget.arrowStyle,
      cornerRadius: widget.cornerRadius,
      lineEndingType: widget.lineEndingType,
      config: widget.edgeConfig,
      marriageStatusProvider: widget.marriageStatusProvider,
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
    // Do a final overlap check
    overlapping = widget.controller.getOverlapping(node);
    
    if (overlapping.isNotEmpty) {
      widget.onDrop?.call(node.data, overlapping.first.data);
    }
    draggedID = null;
    overlapping = [];
    lastDraggedNode = null;
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
