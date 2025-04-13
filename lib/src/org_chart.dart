import 'dart:math';

import 'package:flutter/material.dart';
import 'package:org_chart/src/edge_painter.dart';
import 'package:org_chart/src/custom_animated_positioned.dart';
import 'package:org_chart/src/controller.dart';
import 'package:org_chart/src/node.dart';
import 'package:org_chart/src/node_builder_details.dart';
import 'package:custom_interactive_viewer/custom_interactive_viewer.dart';

/// This is the widget that the user adds to their build method
class OrgChart<E> extends StatefulWidget {
  /// The controller that manages the data and layout
  final OrgChartController<E> controller;

  /// The builder function used to build the nodes
  final Widget Function(NodeBuilderDetails<E> details) builder;

  /// Callback to expose the interactive viewer controller
  final CustomInteractiveViewerController? viewerController;

  // Chart configurations
  final double minScale;
  final double maxScale;
  final bool isDraggable;
  final Curve curve;
  final Duration duration;
  final double cornerRadius;
  final OrgChartArrowStyle arrowStyle;

  // Line painting
  late final Paint linePaint;

  // Callback functions
  final List<PopupMenuEntry<dynamic>> Function(E item)? optionsBuilder;
  final void Function(E item, dynamic value)? onOptionSelect;
  final void Function(E dragged, E target, bool isTargetSubnode)? onDrop;

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
  OrgChart({
    super.key,
    required this.controller,
    this.viewerController,
    required this.builder,
    this.optionsBuilder,
    this.onOptionSelect,
    this.onDrop,
    this.minScale = 0.5,
    this.maxScale = 4.0,
    this.isDraggable = true,
    this.curve = Curves.elasticOut,
    this.arrowStyle = const OrgChartSolidGraphArrow(),
    this.duration = const Duration(milliseconds: 700),
    Paint? linePaint,
    this.cornerRadius = 10.0,

    // Interactive viewer configurations with sensible defaults
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
  }) {
    if (linePaint != null) {
      this.linePaint = linePaint;
    } else {
      this.linePaint = Paint()
        ..color = Colors.black
        ..strokeWidth = 0.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
    }
  }

  @override
  State<OrgChart<E>> createState() => _OrgChartState();
}

class _OrgChartState<E> extends State<OrgChart<E>> {
  List<Node<E>> _overlapping = [];
  String? _draggedID;
  Offset? _panDownPosition;
  // final _transformController = TransformationController();
  late final CustomInteractiveViewerController _viewerController;

  @override
  void initState() {
    super.initState();
    _viewerController =
        widget.viewerController ?? CustomInteractiveViewerController();
    _initializeController();
  }

  void _initializeController() {
    widget.controller.setState = setState;
    widget.controller.centerChart = _viewerController.center;
    widget.controller.setViewerController(_viewerController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewerController.center();
    });
  }

  @override
  void dispose() {
    _viewerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.controller.getSize();
    return CustomInteractiveViewer(
      controller: _viewerController,
      contentSize: widget.controller.getSize(),
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
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _buildEdges(),
            ..._buildNodes(context)..sort((a, b) => a.isBeingDragged ? 1 : -1),
          ],
        ),
      ),
    );
  }

  CustomPaint _buildEdges() {
    return CustomPaint(
      size: MediaQuery.of(context).size,
      painter: EdgePainter<E>(
        controller: widget.controller,
        linePaint: widget.linePaint,
        arrowStyle: widget.arrowStyle,
        cornerRadius: widget.cornerRadius,
      ),
      child: SizedBox.shrink(),
    );
  }

  List<CustomAnimatedPositioned> _buildNodes(BuildContext context,
      {List<Node<E>>? nodesToDraw, bool hidden = false, int level = 1}) {
    final nodes = nodesToDraw ?? widget.controller.roots;
    List<CustomAnimatedPositioned> widgets = [];

    for (int i = 0; i < nodes.length; i++) {
      Node<E> node = nodes[i];
      final isNodeDragged =
          _draggedID == widget.controller.idProvider(node.data);

      widgets.add(_buildNode(context, node, isNodeDragged, hidden, level));

      // Recursively add subnodes
      widgets.addAll(
        _buildNodes(
          context,
          nodesToDraw: widget.controller.getSubNodes(node).toList(),
          hidden: node.hideNodes || hidden,
          level: level + 1,
        ),
      );
    }

    return widgets;
  }

  CustomAnimatedPositioned _buildNode(BuildContext context, Node<E> node,
      bool isBeingDragged, bool hidden, int level) {
    return CustomAnimatedPositioned(
      key: Key("ID: ${widget.controller.idProvider(node.data)}"),
      isBeingDragged: isBeingDragged,
      curve: widget.curve,
      duration: _draggedID != null ? Duration.zero : widget.duration,
      top: node.position.dy,
      left: node.position.dx,
      child: hidden
          ? const SizedBox.shrink()
          : AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: hidden ? 0 : 1,
              child: _buildNodeGestureDetector(
                  context, node, isBeingDragged, level),
            ),
    );
  }

  Widget _buildNodeGestureDetector(
      BuildContext context, Node<E> node, bool isBeingDragged, int level) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onLongPress: () => _showNodeMenu(context, node),
      onSecondaryTapDown: _handleTapDown,
      onSecondaryTap: () => _showNodeMenu(context, node),
      onPanStart: widget.isDraggable ? (details) => _startDragging(node) : null,
      onPanEnd: widget.isDraggable ? (details) => _finishDragging(node) : null,
      onPanUpdate: widget.isDraggable
          ? (details) => _updateDragging(node, details)
          : null,
      child: SizedBox(
        height: widget.controller.boxSize.height,
        width: widget.controller.boxSize.width,
        child: widget.builder(
          NodeBuilderDetails<E>(
            item: node.data,
            level: level,
            hideNodes: ([bool? hide]) => _toggleHideNodes(node, hide),
            nodesHidden: node.hideNodes,
            isBeingDragged: isBeingDragged,
            isOverlapped: _overlapping.isNotEmpty && _overlapping.first == node,
          ),
        ),
      ),
    );
  }

  void _handleTapDown(TapDownDetails details) {
    final RenderBox referenceBox = context.findRenderObject() as RenderBox;
    _panDownPosition = referenceBox.globalToLocal(details.globalPosition);
  }

  void _toggleHideNodes(Node<E> node, bool? hide) {
    final newValue = hide ?? !node.hideNodes;
    if (newValue == node.hideNodes) return;

    setState(() {
      node.hideNodes = newValue;
      widget.controller.calculatePosition();
    });
  }

  void _startDragging(Node<E> node) {
    _draggedID = widget.controller.idProvider(node.data);
    setState(() {});
  }

  void _updateDragging(Node<E> node, DragUpdateDetails details) {
    setState(() {
      node.position = Offset(
        max(node.position.dx + details.delta.dx, 0),
        max(node.position.dy + details.delta.dy, 0),
      );
      _overlapping = widget.controller.getOverlapping(node);
    });
  }

  void _finishDragging(Node<E> node) {
    if (_overlapping.isNotEmpty) {
      widget.onDrop?.call(node.data, _overlapping.first.data,
          _isSubNode(node, _overlapping.first));
    }
    _draggedID = null;
    _overlapping = [];
    setState(() {});
  }

  Future<void> _showNodeMenu(BuildContext context, Node<E> node) async {
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

  bool _isSubNode(Node<E> dragged, Node<E> target) {
    E? current = target.data;
    final draggedId = widget.controller.idProvider(dragged.data);

    while (current != null) {
      final currentToId = widget.controller.toProvider(current);

      if (currentToId == draggedId) {
        return true;
      }

      current = widget.controller.items
          .where(
              (element) => widget.controller.idProvider(element) == currentToId)
          .firstOrNull;
    }

    return false;
  }
}
