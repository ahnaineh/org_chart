import 'dart:math';

import 'package:flutter/material.dart';
import 'package:org_chart/src/common/node.dart';
import 'package:org_chart/src/common/genogram_enums.dart';
import 'package:org_chart/src/controllers/base_controller.dart';

/// The orientation of the genogram chart
enum GenogramOrientation { topToBottom, leftToRight }

/// Controller specifically for genogram charts
class GenogramController<E> extends BaseGraphController<E> {
  GenogramOrientation _orientation;

  /// Get the current orientation of the chart
  GenogramOrientation get orientation => _orientation;

  String? Function(E data) fatherProvider;
  String? Function(E data) motherProvider;
  List<String>? Function(E data) spousesProvider;
  Gender? Function(E data) genderProvider;

  GenogramController({
    required List<E> items,
    Size boxSize = const Size(150, 150),
    double spacing = 30,
    double runSpacing = 60,
    required String Function(E data) idProvider,
    required this.fatherProvider,
    required this.motherProvider,
    required this.spousesProvider,
    required this.genderProvider,
    GenogramOrientation orientation = GenogramOrientation.topToBottom,
  })  : _orientation = orientation,
        super(
          items: items,
          boxSize: boxSize,
          spacing: spacing,
          runSpacing: runSpacing,
          idProvider: idProvider,
        );

  @override
  List<Node<E>> get roots => nodes
      .where((node) =>
          fatherProvider(node.data) == null &&
          motherProvider(node.data) == null)
      .toList();

  List<Node<E>> getChildren(List<Node<E>> nodes) {
    final nodeIds = nodes.map((e) => idProvider(e.data));
    return nodes
        .where((element) =>
            nodeIds.contains(fatherProvider(element.data)) ||
            nodeIds.contains(motherProvider(element.data)))
        .toList();
  }

  List<Node<E>> getParents(Node<E> node) {
    final fatherId = fatherProvider(node.data);
    final motherId = motherProvider(node.data);
    return nodes
        .where((element) =>
            idProvider(element.data) == fatherId ||
            idProvider(element.data) == motherId)
        .toList();
  }

  List<Node<E>> getSpouses(Node<E> node) {
    final spouseIds = spousesProvider(node.data) ?? [];
    return nodes
        .where((element) => spouseIds.contains(idProvider(element.data)))
        .toList();
  }

  void switchOrientation(
      {GenogramOrientation? orientation, bool center = true}) {
    _orientation = orientation ??
        (_orientation == GenogramOrientation.topToBottom
            ? GenogramOrientation.leftToRight
            : GenogramOrientation.topToBottom);
    calculatePosition(center: center);
  }

  @override
  void calculatePosition({bool center = true}) {
    // Keep track of nodes that have already been laid out
    final Set<Node<E>> laidOut = <Node<E>>{};

    // Map to store the rightmost edge of each family branch at each level
    final Map<int, double> levelRightEdges = {};

    // Helper: Get all children of a given couple group from the full nodes list.
    List<Node<E>> getChildrenForGroup(List<Node<E>> parents) {
      final parentIds = parents.map((p) => idProvider(p.data)).toSet();
      return nodes
          .where((child) =>
              parentIds.contains(fatherProvider(child.data)) ||
              parentIds.contains(motherProvider(child.data)))
          .toList();
    }

    // Recursive function: Layout a family subtree starting from a given node at (x, y)
    // Returns the total width of the laid out subtree.
    double layoutFamily(Node<E> node, double x, double y, int level) {
      if (laidOut.contains(node)) {
        return 0;
      }

      // Check if we need to adjust the starting x position based on previous layouts at this level
      if (levelRightEdges.containsKey(level)) {
        // Add extra spacing between family branches to prevent overlaps
        x = max(x, levelRightEdges[level]! + spacing * 2);
      }

      // Build the couple group.
      // If the node is male, add his spouses as part of the same group.
      final List<Node<E>> coupleGroup = <Node<E>>[];
      if (genderProvider(node.data) == Gender.male) {
        coupleGroup.add(node);
        laidOut.add(node);
        // Only add spouses (females) if they haven't been laid out already.
        final List<Node<E>> spouses = getSpouses(node);
        for (final spouse in spouses) {
          if (!laidOut.contains(spouse)) {
            coupleGroup.add(spouse);
            laidOut.add(spouse);
          }
        }
      } else {
        coupleGroup.add(node);
        laidOut.add(node);
      }

      // Calculate the width of the couple group.
      final int groupCount = coupleGroup.length;
      final double groupWidth =
          groupCount * boxSize.width + (groupCount - 1) * spacing;

      // Position each member of the couple group horizontally.
      for (int i = 0; i < groupCount; i++) {
        final double nodeX = x + i * (boxSize.width + spacing);
        coupleGroup[i].position = Offset(nodeX, y);
      }

      // Retrieve children for this couple group from the complete list.
      List<Node<E>> children = getChildrenForGroup(coupleGroup)
          .where((child) => !laidOut.contains(child))
          .toList();

      // If no children, this subtree is just the couple group.
      if (children.isEmpty) {
        // Update the rightmost edge for this level
        levelRightEdges[level] = x + groupWidth;
        return groupWidth;
      }

      // Layout children: Position them in the next level (vertically below current group).
      final double childrenY = y + boxSize.height + runSpacing;
      double childrenTotalWidth = 0;
      double childX = x;

      for (final child in children) {
        // Recursively layout each child's subtree.
        final double subtreeWidth =
            layoutFamily(child, childX, childrenY, level + 1);
        childrenTotalWidth += subtreeWidth;
        // Add additional spacing between siblings to prevent cousin overlaps
        childX += subtreeWidth + spacing * 1.5;
      }

      // Remove the extra spacing after the last child.
      if (children.isNotEmpty) {
        childrenTotalWidth -=
            spacing * 0.5; // Adjust for the extra spacing we added
      }

      // Center the parent couple group above their children.
      final double parentCenter = x + groupWidth / 2;
      final double childrenCenter = x + childrenTotalWidth / 2;
      final double shift = childrenCenter - parentCenter;
      for (final parent in coupleGroup) {
        parent.position =
            Offset(parent.position.dx + shift, parent.position.dy);
      }

      // The total width of this subtree is the maximum of the couple group width and children layout width.
      final totalWidth = max(groupWidth, childrenTotalWidth);

      // Update the rightmost edge for this level
      levelRightEdges[level] = x + totalWidth;

      return totalWidth;
    }

    // Layout each family tree (starting with each root) horizontally.
    double currentX = 0;
    for (final root in roots) {
      if (laidOut.contains(root)) continue;
      final double subtreeWidth = layoutFamily(root, currentX, 0, 0);
      currentX += subtreeWidth +
          spacing * 3; // Add extra spacing between root family trees
    }

    // Update the state and center the graph if needed.
    setState?.call(() {
      nodes = nodes;
    });
    if (center) {
      centerGraph?.call();
    }
  }
}
