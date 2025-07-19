import 'dart:math';

import 'package:custom_interactive_viewer/custom_interactive_viewer.dart';
import 'package:flutter/material.dart';
import 'package:org_chart/src/base/edge_painter_utils.dart';
import 'package:org_chart/src/common/node.dart';
import 'package:org_chart/src/base/base_controller.dart';
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
  final Duration duration;
  final Paint linePaint;
  final double cornerRadius;
  final GraphArrowStyle arrowStyle;

  // Callback functions
  final List<PopupMenuEntry<dynamic>> Function(E item)? optionsBuilder;
  final void Function(E item, dynamic value)? onOptionSelect;

  /// Callback to expose the interactive viewer controller
  final CustomInteractiveViewerController? viewerController;

  // Interactive viewer configurations
  final bool enableZoom;
  final bool enableRotation;
  final bool constrainBounds;
  final bool enableDoubleTapZoom;
  final double doubleTapZoomFactor;
  final bool enableKeyboardControls;
  final double keyboardPanDistance;
  final double keyboardZoomFactor;
  final bool enableKeyRepeat;
  final Duration keyRepeatInitialDelay;
  final Duration keyRepeatInterval;
  final bool enableCtrlScrollToScale;
  final bool enableFling;
  final bool enablePan;
  final FocusNode? focusNode;
  final bool animateKeyboardTransitions;
  final Curve keyboardAnimationCurve;
  final Duration keyboardAnimationDuration;
  final bool invertArrowKeyDirection;

  BaseGraph({
    super.key,
    required this.controller,
    required this.builder,
    this.minScale = 0.001,
    this.maxScale = 5.6,
    this.isDraggable = true,
    this.curve = Curves.elasticOut,
    this.duration = const Duration(milliseconds: 700),
    Paint? linePaint,
    this.optionsBuilder,
    this.onOptionSelect,
    this.arrowStyle = const SolidGraphArrow(),
    this.cornerRadius = 10.0,
    this.viewerController,
    this.enableZoom = true,
    this.enableRotation = false,
    this.constrainBounds = false,
    this.enableDoubleTapZoom = true,
    this.doubleTapZoomFactor = 2.0,
    this.enableKeyboardControls = true,
    this.keyboardPanDistance = 20.0,
    this.keyboardZoomFactor = 1.1,
    this.enableKeyRepeat = true,
    this.keyRepeatInitialDelay = const Duration(milliseconds: 500),
    this.keyRepeatInterval = const Duration(milliseconds: 50),
    this.enableCtrlScrollToScale = true,
    this.enableFling = true,
    this.enablePan = true,
    this.focusNode,
    this.animateKeyboardTransitions = true,
    this.keyboardAnimationCurve = Curves.easeInOut,
    this.keyboardAnimationDuration = const Duration(milliseconds: 300),
    this.invertArrowKeyDirection = false,
  }) : linePaint = linePaint ??
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
  late final CustomInteractiveViewerController viewerController;

  // Protected getters for subclasses
  @protected
  List<Node<E>> get overlappingNodes => overlapping;

  @override
  void initState() {
    super.initState();
    viewerController =
        widget.viewerController ?? CustomInteractiveViewerController();
    _initializeController();
  }

  void _initializeController() {
    widget.controller.setState = setState;
    widget.controller.centerGraph = viewerController.center;
    widget.controller.setViewerController(viewerController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewerController.center();
    });
  }

  @override
  void dispose() {
    if (widget.viewerController == null) {
      viewerController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.controller.getSize();
    return CustomInteractiveViewer(
      controller: viewerController,
      contentSize: size,
      minScale: widget.minScale,
      maxScale: widget.maxScale,
      enableDoubleTapZoom: widget.enableDoubleTapZoom,
      doubleTapZoomFactor: widget.doubleTapZoomFactor,
      enableRotation: widget.enableRotation,
      constrainBounds: widget.constrainBounds,
      enableKeyboardControls: widget.enableKeyboardControls,
      keyboardPanDistance: widget.keyboardPanDistance,
      keyboardZoomFactor: widget.keyboardZoomFactor,
      enableKeyRepeat: widget.enableKeyRepeat,
      keyRepeatInitialDelay: widget.keyRepeatInitialDelay,
      keyRepeatInterval: widget.keyRepeatInterval,
      enableCtrlScrollToScale: widget.enableCtrlScrollToScale,
      enableFling: widget.enableFling,
      focusNode: widget.focusNode,
      enableZoom: widget.enableZoom,
      animateKeyboardTransitions: widget.animateKeyboardTransitions,
      keyboardAnimationCurve: widget.keyboardAnimationCurve,
      keyboardAnimationDuration: widget.keyboardAnimationDuration,
      invertArrowKeyDirection: widget.invertArrowKeyDirection,
      child: RepaintBoundary(
        key: widget.controller.repaintBoundaryKey,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: Stack(
              clipBehavior: Clip.none,
              children: buildGraphElements(context),
            ),
          ),
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

  void toggleHideNodes(Node<E> node, bool? hide, bool center) {
    final newValue = hide ?? !node.hideNodes;
    if (newValue == node.hideNodes) return;

    setState(() {
      node.hideNodes = newValue;
      widget.controller.calculatePosition(center: center);
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
