import 'package:flutter/material.dart';

/// Represents a node in the organization chart.
class ChartNode {
  /// Unique identifier for this node
  final String id;

  /// ID of the parent node. Null for root nodes.
  String? parent;

  /// Display name of the node
  final String name;

  /// Color associated with the node
  Color color;

  ChartNode({
    required this.id,
    this.parent,
    required this.name,
    required this.color,
  });

  /// Create a node from a map representation
  factory ChartNode.fromMap(Map<String, dynamic> map) {
    return ChartNode(
      id: map['id'] as String,
      parent: map['parent'] as String?,
      name: map['name'] as String,
      color: map['color'] as Color,
    );
  }

  /// Convert node to a map representation
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parent': parent,
      'name': name,
      'color': color,
    };
  }
}
