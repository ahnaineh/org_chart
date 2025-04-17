import 'package:custom_interactive_viewer/custom_interactive_viewer.dart';
import 'package:flutter/material.dart';
import 'package:org_chart/src/common/node.dart';

/// Base controller class that all specific graph controllers should extend
abstract class BaseGraphController<E> {
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

  void addItem(E item) {
    nodes.add(Node(data: item));
    calculatePosition();
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
}
