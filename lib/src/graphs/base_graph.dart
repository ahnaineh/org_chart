import 'dart:math';

import 'package:flutter/material.dart';
import 'package:org_chart/src/common/edge_painter.dart';
import 'package:org_chart/src/common/node.dart';
import 'package:org_chart/src/controllers/base_controller.dart';
import 'package:org_chart/src/common/node_builder_details.dart';

/// Base abstract graph widget that provides common functionality for all graph types
abstract class BaseGraph<E> extends StatefulWidget {
  /// The controller that manages the data and layout
  final BaseGraphController<E> controller;

  /// The builder function used to build the nodes
  final Widget Function(NodeBuilderDetails<E> details) builder;

  // Graph configurations
  final double minScale;
  final double maxScale;
  final bool isDraggable;
  final Curve curve;
  final int duration;
  final Paint linePaint;
  final double cornerRadius;
  final GraphArrowStyle arrowStyle;

  // Callback functions
  final List<PopupMenuEntry<dynamic>> Function(E item)? optionsBuilder;
  final void Function(E item, dynamic value)? onOptionSelect;

  BaseGraph({
    super.key,
    required this.controller,
    required this.builder,
    this.minScale = 0.001,
    this.maxScale = 5.6,
    this.isDraggable = true,
    this.curve = Curves.elasticOut,
    this.duration = 700,
    Paint? linePaint,
    this.optionsBuilder,
    this.onOptionSelect,
    this.arrowStyle = const SolidGraphArrow(),
    this.cornerRadius = 10.0,
  })  : linePaint = linePaint ??
            (Paint()
              ..color = Colors.black
              ..strokeWidth = 0.5
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round);
}

/// Base state class for graph widgets
abstract class BaseGraphState<E, T extends BaseGraph<E>> extends State<T> {
  @protected
  List<Node<E>> overlapping = [];
  @protected
  String? draggedID;
  @protected
  Offset? panDownPosition;
  @protected
  final transformController = TransformationController();

  // Protected getters for subclasses
  @protected
  List<Node<E>> get overlappingNodes => overlapping;

  // @protected
  // String? get draggedID => _draggedID;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    widget.controller.setState = setState;
    widget.controller.centerGraph = _centerContent;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerContent();
    });
  }

  void _centerContent() {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final size = renderBox.size;
      final Offset contentSize = widget.controller.getSize();

      final double x = (size.width - contentSize.dx) / 2;
      final double y = (size.height - contentSize.dy) / 2;

      transformController.value = Matrix4.identity()..translate(x, y);

    }
  }

  @override
  void dispose() {
    transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.controller.getSize();
    return InteractiveViewer(
      constrained: false,
      transformationController: transformController,
      boundaryMargin: const EdgeInsets.all(500),
      minScale: widget.minScale,
      maxScale: widget.maxScale,
      child: SizedBox(
        width: size.dx,
        height: size.dy,
        child: Stack(
          clipBehavior: Clip.none,
          children: buildGraphElements(context),
        ),
      ),
    );
  }

  /// Build the elements of the graph
  List<Widget> buildGraphElements(BuildContext context);

  /// Build the nodes of the graph
  List<Widget> buildNodes(BuildContext context,
      {List<Node<E>>? nodesToDraw, bool hidden = false, int level = 1});

  /// Build the lines/edges between nodes
  Widget buildEdges();

  // Common node interaction methods
  void handleTapDown(TapDownDetails details) {
    final RenderBox referenceBox = context.findRenderObject() as RenderBox;
    panDownPosition = referenceBox.globalToLocal(details.globalPosition);
  }

  void toggleHideNodes(Node<E> node, bool? hide) {
    final newValue = hide ?? !node.hideNodes;
    if (newValue == node.hideNodes) return;

    setState(() {
      node.hideNodes = newValue;
      widget.controller.calculatePosition();
    });
  }

  void startDragging(Node<E> node) {
    draggedID = widget.controller.idProvider(node.data);
    setState(() {});
  }

  void updateDragging(Node<E> node, DragUpdateDetails details) {
    setState(() {
      node.position = Offset(
        max(0, node.position.dx + details.delta.dx),
        max(0, node.position.dy + details.delta.dy),
      );

      overlapping = widget.controller.getOverlapping(node);
    });
  }

  Future<void> showNodeMenu(BuildContext context, Node<E> node) async {
    final options = widget.optionsBuilder?.call(node.data) ?? [];
    if (options.isEmpty) return;

    final RenderObject? overlay =
        Overlay.of(context).context.findRenderObject();
    if (panDownPosition == null || overlay == null) return;

    final result = await showMenu(
      context: context,
      position: RelativeRect.fromRect(
          Rect.fromLTWH(panDownPosition!.dx, panDownPosition!.dy, 30, 30),
          Rect.fromLTWH(0, 0, overlay.paintBounds.size.width,
              overlay.paintBounds.size.height)),
      items: options,
    );

    widget.onOptionSelect?.call(node.data, result);
  }

  // Getter for accessing the controller with the correct type
  BaseGraphController<E> get controller => widget.controller;
}
