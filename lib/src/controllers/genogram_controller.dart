import 'package:flutter/material.dart';
import 'package:org_chart/src/common/node.dart';
import 'package:org_chart/src/controllers/base_controller.dart';

/// Enum defining relationship types in a genogram
enum GenogramRelationType {
  marriage,
  divorce,
  separation,
  engagement,
  cohabitation,
  children,
}

/// Controller for genogram charts
class GenogramController<E> extends BaseGraphController<E> {
  /// Determines if couples should be placed side by side
  bool placeCouplesSideBySide;

  /// Spacing between partners in a relationship
  double partnerSpacing;

  /// Function that returns relationship information between nodes
  final GenogramRelationType? Function(E data1, E data2)? relationProvider;

  /// Function that returns gender information for nodes
  final String? Function(E data)? genderProvider;

  GenogramController({
    required List<E> items,
    Size boxSize = const Size(100, 100),
    double spacing = 30,
    double runSpacing = 60,
    required String? Function(E data) idProvider,
    required String? Function(E data) toProvider,
    void Function(E data, String? newID)? toSetter,
    this.placeCouplesSideBySide = true,
    this.partnerSpacing = 40,
    this.relationProvider,
    this.genderProvider,
  }) : super(
          items: items,
          boxSize: boxSize,
          spacing: spacing,
          runSpacing: runSpacing,
          idProvider: idProvider,
          toProvider: toProvider,
          toSetter: toSetter,
        );

  /// Get all relationships in the genogram
  List<GenogramRelation<E>> getRelations() {
    if (relationProvider == null) return [];

    final List<GenogramRelation<E>> relations = [];
    final List<Node<E>> processedNodes = [];

    for (var node1 in super.items.map((e) => Node(data: e))) {
      processedNodes.add(node1);

      for (var node2 in super.items.map((e) => Node(data: e))) {
        if (processedNodes.contains(node2)) continue;

        final relationType = relationProvider!(node1.data, node2.data);
        if (relationType != null) {
          relations.add(GenogramRelation(
            person1: node1,
            person2: node2,
            type: relationType,
          ));
        }
      }
    }

    return relations;
  }

  /// Get marriage/partner relations in the genogram
  List<GenogramRelation<E>> getPartnerRelations() {
    return getRelations()
        .where((relation) =>
            relation.type == GenogramRelationType.marriage ||
            relation.type == GenogramRelationType.divorce ||
            relation.type == GenogramRelationType.separation ||
            relation.type == GenogramRelationType.engagement ||
            relation.type == GenogramRelationType.cohabitation)
        .toList();
  }

  /// Get children relations in the genogram
  List<GenogramRelation<E>> getChildrenRelations() {
    return getRelations()
        .where((relation) => relation.type == GenogramRelationType.children)
        .toList();
  }

  @override
  void calculatePosition({bool center = true}) {
    // Basic implementation - will be enhanced for proper genogram layout
    // in a real implementation with sophisticated family tree positioning algorithm

    // Position nodes - start with a simple grid layout
    int row = 0;
    int col = 0;
    int maxColsPerRow = 4;

    for (Node<E> node in super.roots) {
      node.position = Offset(
          col * (boxSize.width + spacing), row * (boxSize.height + runSpacing));

      col++;
      if (col >= maxColsPerRow) {
        col = 0;
        row++;
      }
    }

    // In a real implementation, we'd handle:
    // - Proper family tree layout with parents above children
    // - Marriage/partnership lines connecting spouses
    // - Blood relation lines
    // - Multiple generations
    // - Handling divorces, remarriages, etc.

    setState?.call(() {});
    if (center) {
      centerGraph?.call();
    }
  }
}

/// Represents a genogram relationship between two nodes
class GenogramRelation<E> {
  final Node<E> person1;
  final Node<E> person2;
  final GenogramRelationType type;

  GenogramRelation({
    required this.person1,
    required this.person2,
    required this.type,
  });
}
