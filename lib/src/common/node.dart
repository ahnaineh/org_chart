import 'package:flutter/material.dart';

/// Represents a node in a graph
class Node<E> {
  /// The position of the node in the graph
  Offset position;

  /// The measured size of the node widget
  Size size;

  /// The animated position used for rendering and edge calculations
  Offset renderPosition;

  /// The data that the node contains (custom data type)
  final E data;

  /// Whether to hide/collapse subnodes
  bool hideNodes;

  /// Creates a new node with the given data
  Node({
    required this.data,
    this.position = Offset.zero,
    this.size = Size.zero,
    this.renderPosition = Offset.zero,
    this.hideNodes = false,
  });

  /// Calculates the offset distance between this node and another node
  Offset distance(Node other) => other.position - position;

  /// The squared distance between nodes (faster calculation than actual distance)
  // double get distanceSquared =>
  //     position.dx * position.dx + position.dy * position.dy;

  @override
  String toString() => 'Node(position: $position, hideNodes: $hideNodes)';
}
