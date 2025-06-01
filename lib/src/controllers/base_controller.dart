import 'dart:typed_data';

import 'package:custom_interactive_viewer/custom_interactive_viewer.dart';
import 'package:flutter/material.dart';
import 'package:org_chart/src/common/node.dart';
import 'package:org_chart/src/exporting/exporting.dart';
import 'package:pdf/widgets.dart' as pw;

/// The orientation of the organizational chart
enum GraphOrientation { topToBottom, leftToRight }

/// Base controller class that all specific graph controllers should extend
abstract class BaseGraphController<E> {
  GraphOrientation orientation;

  GlobalKey repaintBoundaryKey = GlobalKey();

  Future<Uint8List?> exportAsImage() async {
    return await exportChartAsImage(repaintBoundaryKey);
  }

  Future<pw.Document?> exportAsPdf() async {
    return await exportChartAsPdf(repaintBoundaryKey);
  }

  // Common graph controller properties
  Size boxSize;
  double spacing;
  double runSpacing;
  String Function(E data) idProvider;

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
    this.boxSize = const Size(200, 100),
    this.spacing = 20,
    this.runSpacing = 50,
    this.orientation = GraphOrientation.topToBottom,
    required this.idProvider,
  }) {
    this.items = items;
  }

  late List<Node<E>> _nodes;

  List<Node<E>> get nodes => _nodes;

  @protected
  set nodes(List<Node<E>> nodes) => _nodes = nodes;

  List<Node<E>> get roots;

  // Common getters and setters
  List<E> get items => nodes.map((e) => e.data).toList();

  set items(List<E> items) {
    nodes = items.map((e) => Node(data: e)).toList();
    calculatePosition();
  }

  /// Adds a single item to the chart
  /// If an item with the same ID already exists, it will be replaced
  void addItem(E item) {
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
    calculatePosition();
  }

  /// Adds multiple items to the chart
  /// Items with existing IDs will replace the old ones
  void addItems(List<E> items) {
    for (final item in items) {
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
    }
    calculatePosition();
  }

  // /// Removes an item by its ID
  // /// Returns true if the item was found and removed, false otherwise
  // bool removeItem(String itemId) {
  //   final index = nodes.indexWhere((node) => idProvider(node.data) == itemId);
  //   if (index != -1) {
  //     nodes.removeAt(index);
  //     calculatePosition();
  //     return true;
  //   }
  //   return false;
  // }

  // /// Removes multiple items by their IDs
  // /// Returns the number of items that were successfully removed
  // int removeItems(List<String> itemIds) {
  //   int removedCount = 0;
  //   final itemIdSet = Set<String>.from(itemIds);

  //   nodes.removeWhere((node) {
  //     final shouldRemove = itemIdSet.contains(idProvider(node.data));
  //     if (shouldRemove) removedCount++;
  //     return shouldRemove;
  //   });

  //   if (removedCount > 0) {
  //     calculatePosition();
  //   }

  //   return removedCount;
  // }

  /// Removes all items from the chart
  void clearItems() {
    nodes.clear();
    calculatePosition();
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

  Size getSize({Size size = const Size(0, 0)}) {
    for (Node<E> node in nodes) {
      size = Size(
        size.width > node.position.dx + boxSize.width
            ? size.width
            : node.position.dx + boxSize.width,
        size.height > node.position.dy + boxSize.height
            ? size.height
            : node.position.dy + boxSize.height,
      );
    }
    return size;
  }

  List<Node<E>> getOverlapping(Node<E> node) {
    List<Node<E>> overlapping = [];
    final String nodeId = idProvider(node.data);

    for (Node<E> n in nodes) {
      final String nId = idProvider(n.data);
      if (nodeId != nId) {
        Offset offset = node.position - n.position;
        if (offset.dx.abs() < boxSize.width &&
            offset.dy.abs() < boxSize.height) {
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

    // TODO: implement this!
    // // Check if the node is hidden
    // Node<E>? parent = getParent(node);
    // while (parent != null) {
    //   if (parent.hideNodes) return;
    //   parent = getParent(parent);
    // }

    // Create a rectangle representing the node's position and size
    final nodeRect = Rect.fromLTWH(
      node.position.dx,
      node.position.dy,
      boxSize.width,
      boxSize.height,
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
}
