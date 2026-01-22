import 'dart:typed_data';

import 'package:custom_interactive_viewer/custom_interactive_viewer.dart';
import 'package:flutter/material.dart';
import 'package:org_chart/src/common/node.dart';
import 'package:org_chart/src/common/exporting.dart';
import 'package:org_chart/src/base/base_graph_constants.dart';
import 'package:org_chart/src/base/collision_avoidance.dart';
import 'package:pdf/widgets.dart' as pw;

/// The orientation of the organizational chart
enum GraphOrientation { topToBottom, leftToRight }

/// How the graph should react when a node's rendered size changes.
enum SizeChangeAction { ignore, collisionAvoidance }

/// Base controller class that all specific graph controllers should extend
abstract class BaseGraphController<E> {
  GraphOrientation orientation;

  GlobalKey repaintBoundaryKey = GlobalKey();

  Future<Uint8List?> exportAsImage() async {
    return await exportChartAsImage(
      repaintBoundaryKey,
      pixelRatio: BaseGraphConstants.defaultExportPixelRatio,
    );
  }

  Future<pw.Document?> exportAsPdf() async {
    return await exportChartAsPdf(
      repaintBoundaryKey,
      pixelRatio: BaseGraphConstants.defaultExportPixelRatio,
    );
  }

  // Common graph controller properties
  double spacing;
  double runSpacing;
  String Function(E data) idProvider;

  /// Behavior to apply when a node size changes.
  final SizeChangeAction sizeChangeAction;

  /// Minimum size delta required to trigger size-change collision handling.
  final double sizeChangeThreshold;

  /// Preserve manually positioned nodes when resolving size-change collisions.
  final bool preserveManualPositionsOnSizeChange;

  /// Settings for collision avoidance behavior.
  final CollisionAvoidanceSettings collisionSettings;

  /// Current content size of the graph, updated during layout.
  Size _contentSize = Size.zero;

  /// Tracks whether a layout pass is needed.
  bool _layoutRequested = true;

  /// Whether to center the graph after the next layout.
  bool _centerAfterLayout = true;

  /// The ID of the node currently being dragged (if any).
  String? draggedNodeId;

  final Map<String, Offset> _manualPositions = {};

  /// Callback to force a layout pass when requested.
  void Function()? markNeedsLayout;

  // Reference to the interactive viewer controller
  CustomInteractiveViewerController? viewerController;

  /// Sets the interactive viewer controller for node centering
  void setViewerController(CustomInteractiveViewerController controller) {
    viewerController = controller;
  }

  // Internal state management
  void Function(void Function() function)? setState;
  void Function()? centerGraph;

  BaseGraphController({
    required List<E> items,
    this.spacing = 20,
    this.runSpacing = 50,
    this.orientation = GraphOrientation.topToBottom,
    required this.idProvider,
    this.sizeChangeAction = SizeChangeAction.ignore,
    this.sizeChangeThreshold = 0.0,
    this.preserveManualPositionsOnSizeChange = false,
    this.collisionSettings = const CollisionAvoidanceSettings(),
  }) {
    // this.items = items;
    _nodes = items.map((e) => Node(data: e)).toList();
    // Note: calculatePosition() should be called by subclasses after their initialization
  }

  late List<Node<E>> _nodes;

  List<Node<E>> get nodes => _nodes;

  List<Node<E>> get roots;
  List<E> get items => nodes.map((e) => e.data).toList();

  // Common getters and setters

  Size getSize() => _contentSize;

  Size get contentSize => _contentSize;

  void updateContentSize(Size size) {
    _contentSize = size;
  }

  /// Marks a node as manually positioned.
  void markNodeManuallyPositioned(Node<E> node) {
    _manualPositions[idProvider(node.data)] = node.position;
  }

  /// Clears manual position for a single node.
  void clearManualPosition(Node<E> node) {
    _manualPositions.remove(idProvider(node.data));
  }

  /// Clears all manual positions.
  void clearManualPositions() {
    _manualPositions.clear();
  }

  /// Returns the manual position for a node, if set.
  Offset? getManualPosition(Node<E> node) {
    return _manualPositions[idProvider(node.data)];
  }

  /// Returns the IDs of nodes with manual positions.
  Set<String> get manualPositionIds => _manualPositions.keys.toSet();

  /// Runs a global collision pass and triggers a repaint if nodes moved.
  bool applyCollisionAvoidance({
    CollisionAvoidanceSettings? settings,
    Set<String>? pinnedIds,
  }) {
    final bool moved = CollisionAvoidance.resolveGlobal(
      nodes: nodes,
      idProvider: idProvider,
      pinnedIds: pinnedIds ??
          (preserveManualPositionsOnSizeChange ? manualPositionIds : <String>{}),
      settings: settings ?? collisionSettings,
    );

    if (moved) {
      setState?.call(() {});
      markNeedsLayout?.call();
      onLayoutComplete();
    }

    return moved;
  }

  /// Marks layout as required and optionally centers after layout.
  void requestLayout({bool center = true}) {
    _layoutRequested = true;
    _centerAfterLayout = center;
    setState?.call(() {});
    markNeedsLayout?.call();
  }

  bool consumeLayoutRequest() {
    final bool value = _layoutRequested;
    _layoutRequested = false;
    return value;
  }

  bool get isLayoutRequested => _layoutRequested;

  bool consumeCenterAfterLayout() {
    final bool value = _centerAfterLayout;
    _centerAfterLayout = false;
    return value;
  }

  /// Adds a single item to the chart
  /// If an item with the same ID already exists, it will be replaced
  /// [recalculatePosition] determines if the position is to be recalculated directly after adding
  /// you might want to add an item but not recalculate the position immediately
  /// [centerGraph] wether to center the chart after adding the item - if recalculatePosition is true
  void addItem(E item,
      {bool recalculatePosition = true, bool centerGraph = false}) {
    final itemId = idProvider(item);
    final existingIndex =
        nodes.indexWhere((node) => idProvider(node.data) == itemId);

    if (existingIndex != -1) {
      // Replace existing item
      nodes[existingIndex] = Node(data: item);
    } else {
      // Add new item
      nodes.add(Node(data: item));
    }
    if (recalculatePosition) {
      calculatePosition(center: centerGraph);
    }
  }

  /// Adds multiple items to the chart
  /// Items with existing IDs will replace the old ones
  void addItems(List<E> items,
      {bool recalculatePosition = true, bool centerGraph = false}) {
    for (final item in items) {
      addItem(item, recalculatePosition: false, centerGraph: false);
    }
    if (recalculatePosition) {
      calculatePosition(center: centerGraph);
    }
  }

  /// Removes all items from the chart
  void clearItems({bool recalculatePosition = true, bool centerGraph = false}) {
    nodes.clear();
    if (recalculatePosition) {
      calculatePosition(center: centerGraph);
    }
  }

  /// Replaces all items in the chart with new items
  /// This is more efficient than clearing and adding items separately
  void replaceAll(List<E> items,
      {bool recalculatePosition = true, bool centerGraph = false}) {
    _nodes = items.map((e) => Node(data: e)).toList();
    if (recalculatePosition) {
      calculatePosition(center: centerGraph);
    }
  }

  /// Switch the orientation of the chart
  void switchOrientation({GraphOrientation? orientation, bool center = true}) {
    this.orientation = orientation ??
        (this.orientation == GraphOrientation.topToBottom
            ? GraphOrientation.leftToRight
            : GraphOrientation.topToBottom);
    calculatePosition(center: center);
  }

  String get uniqueNodeId {
    int id = 0;
    while (nodes.any((element) => idProvider(element.data) == id.toString())) {
      id++;
    }
    return id.toString();
  }

  void changeNodeIndex(Node<E> node, int index) {
    nodes.remove(node);
    nodes.insert(index == -1 ? nodes.length : index, node);
  }

  void calculatePosition({bool center = true});

  /// Perform a layout pass using measured node sizes.
  void performLayout();

  List<Node<E>> getOverlapping(Node<E> node) {
    List<Node<E>> overlapping = [];
    final String nodeId = idProvider(node.data);

    for (Node<E> n in nodes) {
      final String nId = idProvider(n.data);
      if (nodeId != nId) {
        final Rect nodeRect = Rect.fromLTWH(
          node.position.dx,
          node.position.dy,
          node.size.width,
          node.size.height,
        );
        final Rect otherRect = Rect.fromLTWH(
          n.position.dx,
          n.position.dy,
          n.size.width,
          n.size.height,
        );
        if (nodeRect.overlaps(otherRect)) {
          // Check if the node is hidden
          overlapping.add(n);
        }
      }
    }

    overlapping.sort((a, b) => a
        .distance(node)
        .distanceSquared
        .compareTo(b.distance(node).distanceSquared));

    return overlapping;
  }

  /// Centers a specific node in the view
  ///
  /// [nodeId] The ID of the node to center
  /// [scale] Optional scale level to apply when centering (null means no scale change)
  /// [animate] Whether to animate the centering
  /// [duration] Animation duration when animate is true
  /// [curve] Animation curve when animate is true
  Future<void> centerNode(
    String nodeId, {
    double? scale,
    bool animate = true,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) async {
    if (viewerController == null) return;
    final node = nodes.firstWhere((node) => idProvider(node.data) == nodeId);
    // Create a rectangle representing the node's position and size
    final nodeRect = Rect.fromLTWH(
      node.position.dx,
      node.position.dy,
      node.size.width,
      node.size.height,
    );

    // Center on this rectangle
    await viewerController!.centerOnRect(
      nodeRect,
      scale: scale,
      animate: animate,
      duration: duration,
      curve: curve,
    );
  }

  /// Hook for controllers that need to react after a layout pass.
  void onLayoutComplete() {}

  /// Hook to update spatial indexes when a node is dragged.
  void updateNodePosition(Node<E> node, Offset oldPosition) {}
}
