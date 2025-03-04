import 'package:flutter/material.dart';
import 'package:org_chart/src/common/custom_animated_positioned.dart';
import 'package:org_chart/src/common/edge_painter.dart';
import 'package:org_chart/src/common/node.dart';
import 'package:org_chart/src/common/node_builder_details.dart';
import 'package:org_chart/src/controllers/genogram_controller.dart';
import 'package:org_chart/src/graphs/base_graph.dart';
import 'package:org_chart/src/graphs/genogram/edge_painter.dart';

/// A widget that displays a family relationship chart (genogram)
class Genogram<E> extends BaseGraph<E> {
  /// Paint for partnership/marriage relationships
  final Paint? partnershipPaint;

  /// Paint for children connections
  final Paint? childrenPaint;

  Genogram({
    Key? key,
    required GenogramController<E> controller,
    required Widget Function(NodeBuilderDetails<E> details) builder,
    double minScale = 0.001,
    double maxScale = 5.6,
    bool isDraggable = true,
    Curve curve = Curves.elasticOut,
    int duration = 700,
    Paint? linePaint,
    this.partnershipPaint,
    this.childrenPaint,
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
      genogramController: controller,
      linePaint: widget.linePaint,
      partnershipPaint: widget.partnershipPaint,
      childrenPaint: widget.childrenPaint,
      arrowStyle: const SolidGraphArrow(),
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
      final isBeingDragged = nodeId == draggedID;

      // Get gender information if available
      final genogramController = controller;
      if (genogramController.genderProvider != null) {
        // We're using the gender for styling in the builder below
        // No need to store it in a variable
      }

      nodeWidgets.add(
        CustomAnimatedPositioned(
          key: ValueKey(nodeId),
          isBeingDragged: isBeingDragged,
          duration: Duration(milliseconds: widget.duration),
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
                  isBeingDragged: isBeingDragged,
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
  GenogramController<E> get controller =>
      widget.controller as GenogramController<E>;
}
