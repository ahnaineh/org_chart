import 'package:flutter/material.dart';
import 'package:org_chart/src/common/node.dart';

/// Base controller class that all specific graph controllers should extend
abstract class BaseGraphController<E> {
  // Common graph controller properties
  late List<Node<E>> _nodes;
  Size boxSize;
  double spacing;
  double runSpacing;
  String? Function(E data) idProvider;
  String? Function(E data) toProvider;
  void Function(E data, String? newID)? toSetter;

  // Internal state management
  void Function(void Function() function)? setState;
  void Function()? centerGraph;

  BaseGraphController({
    required List<E> items,
    this.boxSize = const Size(200, 100),
    this.spacing = 20,
    this.runSpacing = 50,
    required this.idProvider,
    required this.toProvider,
    this.toSetter,
  }) {
    this.items = items;
  }

  // Common getters and setters
  List<E> get items => _nodes.map((e) => e.data).toList();

  set items(List<E> items) {
    _nodes = items.map((e) => Node(data: e)).toList();
    calculatePosition();
  }

  void addItem(E item) {
    _nodes.add(Node(data: item));
    calculatePosition();
  }

  String get uniqueNodeId {
    int id = 0;
    while (_nodes.any((element) => idProvider(element.data) == id.toString())) {
      id++;
    }
    return id.toString();
  }

  void changeNodeIndex(Node<E> node, int index) {
    _nodes.remove(node);
    _nodes.insert(index == -1 ? _nodes.length : index, node);
  }

  // Node-related methods
  List<Node<E>> get roots =>
      _nodes.where((node) => getLevel(node) == 1).toList();

  List<Node<E>> getSubNodes(Node<E> node) {
    final nodeId = idProvider(node.data);
    return _nodes
        .where((element) => toProvider(element.data) == nodeId)
        .toList();
  }

  bool allLeaf(List<Node<E>> nodes) {
    return nodes
        .every((element) => getSubNodes(element).isEmpty || element.hideNodes);
  }

  // Methods to be implemented by subclasses
  void calculatePosition({bool center = true});

  Offset getSize({Offset offset = const Offset(0, 0)}) {
    for (Node<E> node in _nodes) {
      offset = Offset(
        offset.dx > node.position.dx + boxSize.width
            ? offset.dx
            : node.position.dx + boxSize.width,
        offset.dy > node.position.dy + boxSize.height
            ? offset.dy
            : node.position.dy + boxSize.height,
      );
    }
    return offset;
  }

  List<Node<E>> getOverlapping(Node<E> node) {
    List<Node<E>> overlapping = [];
    final String nodeId = idProvider(node.data) ?? '';

    for (Node<E> n in _nodes) {
      final String nId = idProvider(n.data) ?? '';
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

  // Helper method for determining node level
  @protected
  int getLevel(Node<E> node) {
    int level = 1;
    Node<E>? current = node;
    String? currentToId;

    while (current != null) {
      currentToId = toProvider(current.data);
      if (currentToId == null) break;

      try {
        current = _nodes.firstWhere((n) => idProvider(n.data) == currentToId);
        level++;
      } catch (_) {
        break;
      }
    }
    return level;
  }
}
