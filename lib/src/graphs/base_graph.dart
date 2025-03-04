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
  final void Function(E dragged, E target, bool isTargetSubnode)? onDrop;

  BaseGraph({
    Key? key,
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
    this.onDrop,
    this.arrowStyle = const SolidGraphArrow(),
    this.cornerRadius = 10.0,
  })  : this.linePaint = linePaint ??
            (Paint()
              ..color = Colors.black
              ..strokeWidth = 0.5
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round),
        super(key: key);
}

/// Base state class for graph widgets
abstract class BaseGraphState<E, T extends BaseGraph<E>> extends State<T> {
  List<Node<E>> _overlapping = [];
  String? _draggedID;
  Offset? _panDownPosition;
  final _transformController = TransformationController();

  // Protected getters for subclasses
  @protected
  List<Node<E>> get overlappingNodes => _overlapping;

  @protected
  String? get draggedID => _draggedID;

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

      _transformController.value = Matrix4.identity()..translate(x, y);
    }
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.controller.getSize();
    return InteractiveViewer(
      constrained: false,
      transformationController: _transformController,
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
    _panDownPosition = referenceBox.globalToLocal(details.globalPosition);
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
    _draggedID = widget.controller.idProvider(node.data);
    setState(() {});
  }

  void updateDragging(Node<E> node, DragUpdateDetails details) {
    setState(() {
      node.position = Offset(
        node.position.dx + details.delta.dx,
        node.position.dy + details.delta.dy,
      ).translate(0, 0); // Ensure positive coordinates

      _overlapping = widget.controller.getOverlapping(node);
    });
  }

  void finishDragging(Node<E> node) {
    if (_overlapping.isNotEmpty) {
      widget.onDrop?.call(node.data, _overlapping.first.data,
          isSubNode(node, _overlapping.first));
    }
    _draggedID = null;
    _overlapping = [];
    setState(() {});
  }

  Future<void> showNodeMenu(BuildContext context, Node<E> node) async {
    final options = widget.optionsBuilder?.call(node.data) ?? [];
    if (options.isEmpty) return;

    final RenderObject? overlay =
        Overlay.of(context).context.findRenderObject();
    if (_panDownPosition == null || overlay == null) return;

    final result = await showMenu(
      context: context,
      position: RelativeRect.fromRect(
          Rect.fromLTWH(_panDownPosition!.dx, _panDownPosition!.dy, 30, 30),
          Rect.fromLTWH(0, 0, overlay.paintBounds.size.width,
              overlay.paintBounds.size.height)),
      items: options,
    );

    widget.onOptionSelect?.call(node.data, result);
  }

  bool isSubNode(Node<E> dragged, Node<E> target) {
    E? current = target.data;
    final draggedId = widget.controller.idProvider(dragged.data);

    while (current != null) {
      final currentToId = widget.controller.toProvider(current);

      if (currentToId == draggedId) {
        return true;
      }

      try {
        final matchingParents = widget.controller.items.where(
            (element) => widget.controller.idProvider(element) == currentToId);
        current = matchingParents.isNotEmpty ? matchingParents.first : null;
      } catch (_) {
        break;
      }
    }

    return false;
  }

  // Getter for accessing the controller with the correct type
  BaseGraphController<E> get controller => widget.controller;
}
