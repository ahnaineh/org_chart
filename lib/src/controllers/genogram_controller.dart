import 'dart:math';

import 'package:flutter/material.dart';
import 'package:org_chart/src/common/node.dart';
import 'package:org_chart/src/controllers/base_controller.dart';

/// Defines the orientation mode for genogram chart layout
/// - topToBottom: Family trees are laid out from top (ancestors) to bottom (descendants)
/// - leftToRight: Family trees are laid out from left (ancestors) to right (descendants)
enum GenogramOrientation { topToBottom, leftToRight }

/// Controller responsible for managing and laying out genogram (family tree) charts
///
/// A genogram is a visual representation of a family tree that displays detailed data on relationships
/// and medical history across generations. This controller handles:
/// - Node positioning and layout algorithms
/// - Parent-child relationship tracking
/// - Spouse relationship management
/// - Gender-based node positioning
/// - Multi-generational hierarchy visualization
class GenogramController<E> extends BaseGraphController<E> {
  /// Current orientation setting for the chart
  GenogramOrientation _orientation;

  /// Returns the current orientation setting of the chart
  GenogramOrientation get orientation => _orientation;

  /// Function to extract the father's ID from an item
  /// Returns null if the item has no father (root node)
  String? Function(E data) fatherProvider;

  /// Function to extract the mother's ID from an item
  /// Returns null if the item has no mother (root node)
  String? Function(E data) motherProvider;

  /// Function to extract a list of spouse IDs from an item
  /// Returns an empty list if the item has no spouses
  List<String>? Function(E data) spousesProvider;

  /// Function to determine the gender of an item
  /// - 0 represents male
  /// - 1 represents female
  /// Used for correct positioning in family groups and relationship visualization
  int Function(E data) genderProvider;

  /// Creates a genogram controller with the specified parameters
  ///
  /// [items]: List of data items to display in the genogram
  /// [boxSize]: Size of each node box (default: 150x150)
  /// [spacing]: Horizontal spacing between adjacent nodes (default: 30)
  /// [runSpacing]: Vertical spacing between generations (default: 60)
  /// [idProvider]: Function to extract a unique identifier from each data item
  /// [fatherProvider]: Function to extract the father's ID from a data item
  /// [motherProvider]: Function to extract the mother's ID from a data item
  /// [spousesProvider]: Function to extract spouse IDs from a data item
  /// [genderProvider]: Function to determine gender (0=male, 1=female) of a data item
  /// [orientation]: Initial layout orientation (default: topToBottom)
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

  /// Identifies the root nodes of the genogram
  ///
  /// Root nodes are those without any parent (father or mother),
  /// representing the oldest generation in the genogram.
  /// These nodes will be placed at the top/left depending on orientation.
  @override
  List<Node<E>> get roots => nodes
      .where((node) =>
          fatherProvider(node.data) == null &&
          motherProvider(node.data) == null)
      .toList();

  /// Convenience method to check if a data item represents a male
  /// Returns true if the gender code is 0
  bool isMale(E data) => genderProvider(data) == 0;

  /// Convenience method to check if a data item represents a female
  /// Returns true if the gender code is 1
  bool isFemale(E data) => genderProvider(data) == 1;

  /// Retrieves all children nodes for a given list of parent nodes
  ///
  /// This function finds all individuals whose father or mother ID
  /// matches any ID in the provided parent node list.
  ///
  /// [nodes]: List of potential parent nodes to find children for
  /// Returns a list of nodes representing the children of any parent in the input list
  List<Node<E>> getChildren(List<Node<E>> nodes) {
    // Extract IDs from the parent nodes
    final nodeIds = nodes.map((e) => idProvider(e.data));

    // Return all nodes whose father or mother ID matches any parent ID
    return this
        .nodes
        .where((element) =>
            nodeIds.contains(fatherProvider(element.data)) ||
            nodeIds.contains(motherProvider(element.data)))
        .toList();
  }

  /// Retrieves the parent nodes for a given child node
  ///
  /// This function finds the father and mother nodes of a specific individual.
  ///
  /// [node]: Child node to find parents for
  /// Returns a list of nodes containing the father and/or mother nodes (0-2 items)
  List<Node<E>> getParents(Node<E> node) {
    // Extract the father and mother IDs from the child data
    final fatherId = fatherProvider(node.data);
    final motherId = motherProvider(node.data);

    // Return nodes that match either father or mother ID
    return nodes
        .where((element) =>
            idProvider(element.data) == fatherId ||
            idProvider(element.data) == motherId)
        .toList();
  }

  /// Retrieves all spouse nodes for a given data item
  ///
  /// This function finds all individuals who are married to the specified person,
  /// whether the relationship is stored on this person or on their spouse.
  ///
  /// [data]: Data item to find spouses for
  /// Returns a list of nodes representing the spouses of the input data
  List<Node<E>> getSpouseList(E data) {
    // Get the unique ID of this person
    final String personId = idProvider(data);

    // Create a set to avoid duplicate spouses
    final Set<Node<E>> spouses = {};

    // Method 1: Direct approach - get spouses listed on this person
    final spouseIds = spousesProvider(data) ?? [];
    spouses.addAll(
        nodes.where((node) => spouseIds.contains(idProvider(node.data))));
    // TODO: update this. use a where function
    // Method 2: Reverse lookup - find nodes that list this person as their spouse
    for (final Node<E> potentialSpouse in nodes) {
      // Skip self
      if (idProvider(potentialSpouse.data) == personId) continue;

      // Check if this potential spouse lists our person as their spouse
      final otherSpouseIds = spousesProvider(potentialSpouse.data) ?? [];
      if (otherSpouseIds.contains(personId)) {
        spouses.add(potentialSpouse);
      }
    }

    return spouses.toList();
  }

  /// Changes the orientation of the genogram layout
  ///
  /// If no orientation is provided, toggles between topToBottom and leftToRight.
  /// After changing orientation, repositions all nodes according to the new layout.
  ///
  /// [orientation]: Optional specific orientation to switch to
  /// [center]: Whether to center the graph after layout (default: true)
  void switchOrientation(
      {GenogramOrientation? orientation, bool center = true}) {
    // Switch orientation (toggle if not specified)
    _orientation = orientation ??
        (_orientation == GenogramOrientation.topToBottom
            ? GenogramOrientation.leftToRight
            : GenogramOrientation.topToBottom);

    // Recalculate all positions with the new orientation
    calculatePosition(center: center);
  }

  /// Calculates the positions of all nodes in the genogram
  ///
  /// This is the core layout algorithm for the genogram. It:
  /// 1. Identifies root nodes (individuals with no parents)
  /// 2. For each root, recursively lays out their family tree
  /// 3. Positions male-female couples side by side
  /// 4. Positions children below their parents
  /// 5. Ensures proper spacing between family units
  /// 6. Centers parent groups above their children
  ///
  /// [center]: Whether to center the graph after layout (default: true)
  @override
  void calculatePosition({bool center = true}) {
    // Track nodes that have been positioned to avoid duplicates
    final Set<Node<E>> laidOut = <Node<E>>{};

    // For each level (generation), track the rightmost edge to prevent overlaps
    final Map<int, double> levelRightEdges = {};

    // Minimum X position to ensure nothing goes negative
    final double minX = spacing * 2;

    /// Internal helper: Gets all children of a given couple group
    ///
    /// A couple group is a list of nodes that form a family unit (husband, wife/wives)
    /// This function finds all children whose father or mother is in the couple group.
    ///
    /// [parents]: List of parent nodes forming a couple group
    /// Returns all nodes that have a parent in the input list
    List<Node<E>> getChildrenForGroup(List<Node<E>> parents) {
      // Extract IDs from all parents in the couple group
      final parentIds = parents.map((p) => idProvider(p.data)).toSet();

      // Return all nodes whose father or mother ID is in the parent set
      return nodes
          .where((child) =>
              parentIds.contains(fatherProvider(child.data)) ||
              parentIds.contains(motherProvider(child.data)))
          .toList();
    }

    /// Recursive function to layout a family subtree
    ///
    /// This function positions a node, its spouses, and all descendants.
    /// Returns the total width required for this subtree.
    ///
    /// [node]: Current node being positioned
    /// [x]: Starting x-coordinate for this node
    /// [y]: Y-coordinate for this node
    /// [level]: Current generation level (0 = roots)
    double layoutFamily(Node<E> node, double x, double y, int level) {
      // Ensure x is never less than minX
      x = max(x, minX);

      // Skip if this node has already been positioned
      if (laidOut.contains(node)) {
        return 0; // No additional width required
      }

      // Check if we need to adjust horizontal position to avoid overlapping with existing nodes
      if (levelRightEdges.containsKey(level)) {
        // Ensure we start after the rightmost node at this level plus spacing
        x = max(x, levelRightEdges[level]! + spacing * 2);
      }

      // Build the couple group (a husband and his wife/wives, or just a single individual)
      final List<Node<E>> coupleGroup = <Node<E>>[];

      // Handle male nodes - include the man and all his spouses in the group
      if (isMale(node.data)) {
        // Add the male node first
        coupleGroup.add(node);
        laidOut.add(node);

        // Get all spouses, regardless of whether they've been positioned
        final List<Node<E>> spouses = getSpouseList(node.data);

        // For any spouse that has been positioned already, remove from laidOut
        // so they can be repositioned with this husband
        for (final spouse in spouses) {
          laidOut.remove(spouse);
        }

        // Add all wives to the right of the husband
        coupleGroup.addAll(spouses);
        laidOut.addAll(spouses);
      }
      // Handle female nodes - if processing a female directly, she forms her own group
      else {
        // Check if this woman is a spouse of a male we'll process later
        // If so, skip her as she'll be positioned with her husband
        final bool willBeSpouseOfLaterMale = nodes
            .where((n) => !laidOut.contains(n))
            .where((n) => isMale(n.data))
            .any((n) {
          final spouseIds = spousesProvider(n.data) ?? [];
          return spouseIds.contains(idProvider(node.data));
        });

        if (!willBeSpouseOfLaterMale) {
          coupleGroup.add(node);
          laidOut.add(node);
        }
      }

      // If no nodes in couple group (might happen if we skip a female spouse), return 0
      if (coupleGroup.isEmpty) {
        return 0;
      }

      // Calculate the total width needed for this couple group
      // groupWidth = number of individuals * box width + spacing between them
      final int groupCount = coupleGroup.length;
      final double groupWidth =
          groupCount * boxSize.width + (groupCount - 1) * spacing;

      // Position each person in the couple group horizontally in a row
      for (int i = 0; i < groupCount; i++) {
        final double nodeX = x + i * (boxSize.width + spacing);
        coupleGroup[i].position = Offset(nodeX, y);
      }

      // Get all children for this couple group that haven't been positioned yet
      List<Node<E>> children = getChildrenForGroup(coupleGroup)
          .where((child) => !laidOut.contains(child))
          .toList();

      // Sort children by parent combinations to group siblings with the same parents
      children.sort((a, b) {
        // First, identify the husband in the couple group (if any)
        final Node<E>? husband =
            coupleGroup.where((node) => isMale(node.data)).firstOrNull;

        if (husband != null) {
          final String husbandId = idProvider(husband.data);

          // Get all wives/spouses in the order they appear in the couple group
          final List<String> spouseIds = coupleGroup
              .where((node) => !isMale(node.data))
              .map((node) => idProvider(node.data))
              .toList();

          // Check if each child belongs to the husband
          final bool aIsHusbandChild = fatherProvider(a.data) == husbandId;
          final bool bIsHusbandChild = fatherProvider(b.data) == husbandId;

          if (aIsHusbandChild && bIsHusbandChild) {
            // Both are husband's children, now check mother
            final String? aMotherId = motherProvider(a.data);
            final String? bMotherId = motherProvider(b.data);

            // If either has no mother, those come first
            if (aMotherId == null && bMotherId != null) return -1;
            if (aMotherId != null && bMotherId == null) return 1;
            if (aMotherId == null && bMotherId == null) return 0;

            // Both have mothers, sort by the mother's position in spouse list
            final int aMotherIndex = spouseIds.indexOf(aMotherId!);
            final int bMotherIndex = spouseIds.indexOf(bMotherId!);

            // If mother is in spouse list, sort by their order
            if (aMotherIndex != -1 && bMotherIndex != -1) {
              return aMotherIndex - bMotherIndex;
            }

            // If one mother is in spouse list but other isn't
            if (aMotherIndex != -1) return -1;
            if (bMotherIndex != -1) return 1;
          }

          // If only one is husband's child, put it first
          if (aIsHusbandChild && !bIsHusbandChild) return -1;
          if (!aIsHusbandChild && bIsHusbandChild) return 1;
        }

        // Default fallback: sort by parent combinations as before
        final aFather = fatherProvider(a.data);
        final bFather = fatherProvider(b.data);
        final aMother = motherProvider(a.data);
        final bMother = motherProvider(b.data);

        // Compare parent combinations
        final aCombo = '${aFather ?? ""}:${aMother ?? ""}';
        final bCombo = '${bFather ?? ""}:${bMother ?? ""}';
        return aCombo.compareTo(bCombo);
      });

      // If no children, this subtree is just the couple group with no descendants
      if (children.isEmpty) {
        // Update the rightmost edge for this level
        levelRightEdges[level] = x + groupWidth;
        return groupWidth;
      }

      // Position all children below their parents
      final double childrenY = y + boxSize.height + runSpacing;
      double childrenTotalWidth =
          0; // Track total width required for all children
      double childX = x; // Starting x position for first child

      // Position each child and their descendants recursively
      for (final child in children) {
        // For each child, calculate the width of their entire subtree
        final double subtreeWidth =
            layoutFamily(child, childX, childrenY, level + 1);

        // Add this subtree's width to the running total
        childrenTotalWidth += subtreeWidth;

        // Move the next child's position to the right, adding extra spacing
        // The 1.5x spacing factor provides better separation between sibling families
        childX += subtreeWidth + spacing * 1.5;
      }

      // Remove the extra spacing after the last child (which wasn't needed)
      if (children.isNotEmpty) {
        childrenTotalWidth -=
            spacing * 0.5; // Adjust for the extra spacing we added
      }

      // Center the parent couple group above their children to make the tree visually balanced
      // 1. Calculate center point of couple group
      final double parentCenter = x + groupWidth / 2;
      // 2. Calculate center point of children's total width
      final double childrenCenter = x + childrenTotalWidth / 2;
      // 3. Calculate how much to shift parents to center them
      final double shift = childrenCenter - parentCenter;

      // Apply the shift to each parent in the couple group
      for (final parent in coupleGroup) {
        parent.position =
            Offset(parent.position.dx + shift, parent.position.dy);
      }

      // The total width of this subtree is the maximum of:
      // - couple group width (parents)
      // - total width of all children subtrees
      final totalWidth = max(groupWidth, childrenTotalWidth);

      // Update the rightmost edge for this level
      levelRightEdges[level] = x + totalWidth;

      // Return the total width needed for this entire family subtree
      return totalWidth;
    }

    // Prioritize processing male nodes first among roots
    List<Node<E>> sortedRoots = [...roots];
    sortedRoots.sort((a, b) {
      // Males come first
      if (isMale(a.data) && !isMale(b.data)) return -1;
      if (!isMale(a.data) && isMale(b.data)) return 1;

      // Otherwise sort by ID for consistency
      return idProvider(a.data).compareTo(idProvider(b.data));
    });

    // Layout each family tree (starting with each root) horizontally
    double currentX = minX; // Start with minimum X value

    // Process each root node (individuals with no parents)
    for (final root in sortedRoots) {
      if (laidOut.contains(root)) continue; // Skip if already positioned

      // Layout this root's entire family tree and get its width
      final double subtreeWidth = layoutFamily(root, currentX, 0, 0);

      // Move to the position for the next root, adding extra spacing
      currentX += subtreeWidth + spacing * 3;
    }

    // Notify listeners that positions have been updated
    setState?.call(() {
      nodes = nodes;
    });

    // Center the graph if requested
    if (center) {
      centerGraph?.call();
    }
  }
}
