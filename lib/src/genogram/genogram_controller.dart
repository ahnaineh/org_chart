import 'dart:math';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:org_chart/src/common/node.dart';
import 'package:org_chart/src/base/base_controller.dart';

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

  /// Cache for getParents method to improve performance
  final Map<String, List<Node<E>>> _parentsCache = {};

  /// Cache for getSpouseList method to improve performance
  final Map<String, List<Node<E>>> _spousesCache = {};

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
    required super.items,
    super.boxSize = const Size(150, 150),
    super.spacing = 30,
    super.runSpacing = 60,
    super.orientation = GraphOrientation.topToBottom,
    required super.idProvider,
    required this.fatherProvider,
    required this.motherProvider,
    required this.spousesProvider,
    required this.genderProvider,
  });

  /// Clears all caches when items change
  // @override
  // set items(List<E> items) {
  //   _clearCaches();
  //   super.items = items;
  // }

  @override
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

  /// Clears all internal caches
  void _clearCaches() {
    _parentsCache.clear();
    _spousesCache.clear();
  }

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
  /// Results are cached for performance.
  ///
  /// [node]: Child node to find parents for
  /// Returns a list of nodes containing the father and/or mother nodes (0-2 items)
  List<Node<E>> getParents(Node<E> node) {
    final String nodeId = idProvider(node.data);

    // Return cached result if available
    if (_parentsCache.containsKey(nodeId)) {
      return _parentsCache[nodeId]!;
    }

    // Extract the father and mother IDs from the child data
    final fatherId = fatherProvider(node.data);
    final motherId = motherProvider(node.data);

    // Find nodes that match either father or mother ID
    final result = nodes
        .where((element) =>
            idProvider(element.data) == fatherId ||
            idProvider(element.data) == motherId)
        .toList();

    // Cache the result for future calls
    _parentsCache[nodeId] = result;

    return result;
  }

  /// Retrieves all spouse nodes for a given data item
  ///
  /// This function finds all individuals who are married to the specified person,
  /// whether the relationship is stored on this person or on their spouse.
  /// Results are cached for performance.
  ///
  /// [data]: Data item to find spouses for
  /// Returns a list of nodes representing the spouses of the input data
  List<Node<E>> getSpouseList(E data) {
    // Get the unique ID of this person
    final String personId = idProvider(data);

    // Return cached result if available
    if (_spousesCache.containsKey(personId)) {
      return _spousesCache[personId]!;
    }

    // Create a set to avoid duplicate spouses
    final Set<Node<E>> spouses = {};

    // Method 1: Direct approach - get spouses listed on this person
    final spouseIds = spousesProvider(data) ?? [];
    spouses.addAll(
        nodes.where((node) => spouseIds.contains(idProvider(node.data))));

    // Method 2: Reverse lookup - find nodes that list this person as their spouse
    // Using where function for better readability and performance
    spouses.addAll(nodes.where((potentialSpouse) {
      // Skip self
      if (idProvider(potentialSpouse.data) == personId) return false;

      // Check if this potential spouse lists our person as their spouse
      final otherSpouseIds = spousesProvider(potentialSpouse.data) ?? [];
      return otherSpouseIds.contains(personId);
    }));

    // Cache the result for future calls
    final result = spouses.toList();
    _spousesCache[personId] = result;

    return result;
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
    // Clear caches before recalculating positions
    _clearCaches();

    // Track nodes that have been positioned to avoid duplicates
    final Set<Node<E>> laidOut = <Node<E>>{};

    // For each level (generation), track the rightmost edge (or bottommost edge for leftToRight)
    // to prevent overlaps
    final Map<int, double> levelEdges = {};

    // Minimum position to ensure nothing goes negative
    final double minPos = spacing * 2;

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
    /// Returns the total width (or height for leftToRight) required for this subtree.
    ///
    /// [node]: Current node being positioned
    /// [x]: Starting x-coordinate for this node
    /// [y]: Y-coordinate for this node
    /// [level]: Current generation level (0 = roots)
    double layoutFamily(Node<E> node, double x, double y, int level) {
      // Ensure starting position is never less than minimum
      if (orientation == GraphOrientation.topToBottom) {
        x = max(x, minPos);
      } else {
        y = max(y, minPos);
      }

      // Skip if this node has already been positioned
      if (laidOut.contains(node)) {
        return 0; // No additional space required
      }

      // Check if we need to adjust position to avoid overlapping with existing nodes
      if (levelEdges.containsKey(level)) {
        if (orientation == GraphOrientation.topToBottom) {
          // Ensure we start after the rightmost node at this level plus spacing
          x = max(x, levelEdges[level]! + spacing);
        } else {
          // For leftToRight, ensure we start after the bottommost node plus spacing
          y = max(y, levelEdges[level]! + spacing);
        }
      } else {
        levelEdges[level] = orientation == GraphOrientation.topToBottom ? x : y;
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

        // Add all wives to the right/below of the husband depending on orientation
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

      // Calculate the total width or height needed for this couple group
      final int groupCount = coupleGroup.length;
      final double groupSize = groupCount *
              (orientation == GraphOrientation.topToBottom
                  ? boxSize.width
                  : boxSize.height) +
          (groupCount - 1) * spacing;

      // Position each person in the couple group in a row or column depending on orientation
      for (int i = 0; i < groupCount; i++) {
        final double offset = i *
            (orientation == GraphOrientation.topToBottom
                ? boxSize.width + spacing
                : boxSize.height + spacing);

        if (orientation == GraphOrientation.topToBottom) {
          final double nodeX = x + offset;
          coupleGroup[i].position = Offset(nodeX, y);
        } else {
          final double nodeY = y + offset;
          coupleGroup[i].position = Offset(x, nodeY);
        }
      }

      // Get all children for this couple group that haven't been positioned yet
      List<Node<E>> children = getChildrenForGroup(coupleGroup)
          .where((child) => !laidOut.contains(child))
          .toList();

      // Sort children using the dedicated method
      sortChildrenBySiblingGroups(children, coupleGroup);

      // If no children, this subtree is just the couple group with no descendants
      if (children.isEmpty) {
        // Update the edge for this level
        levelEdges[level] = orientation == GraphOrientation.topToBottom
            ? x + groupSize
            : y + groupSize;
        return groupSize;
      }

      // Distance for children from parent
      final double childDistance = orientation == GraphOrientation.topToBottom
          ? boxSize.height + runSpacing
          : boxSize.width + runSpacing;

      // Position coordinates for children based on orientation
      final double childrenX =
          orientation == GraphOrientation.topToBottom ? x : x + childDistance;

      final double childrenY =
          orientation == GraphOrientation.topToBottom ? y + childDistance : y;

      double childrenTotalSize =
          0; // Track total width/height required for all children
      double childPos =
          orientation == GraphOrientation.topToBottom ? childrenX : childrenY;

      // Position each child and their descendants recursively
      for (final child in children) {
        // For each child, calculate the size of their entire subtree
        final double subtreeSize = orientation == GraphOrientation.topToBottom
            ? layoutFamily(child, childPos, childrenY, level + 1)
            : layoutFamily(child, childrenX, childPos, level + 1);

        // Add this subtree's size to the running total
        childrenTotalSize += subtreeSize;

        // Move the next child's position, adding extra spacing
        childPos += subtreeSize + spacing * 1.5;
      }

      // Calculate true children size by removing the extra spacing after the last child
      final double trueChildrenSize = children.isNotEmpty
          ? childrenTotalSize -
              spacing * 0.5 // Remove extra spacing from last child
          : 0;

      // Center the parent couple group above/before their children to make the tree visually balanced
      double parentCenter, childrenCenter, shift;

      if (orientation == GraphOrientation.topToBottom) {
        parentCenter = x + groupSize / 2;
        childrenCenter = x + trueChildrenSize / 2;
      } else {
        parentCenter = y + groupSize / 2;
        childrenCenter = y + trueChildrenSize / 2;
      }

      shift = childrenCenter - parentCenter;

      // Only apply shifts when there are actually children and their size is greater than parents
      if (children.isNotEmpty && trueChildrenSize > groupSize) {
        // Apply the shift to each parent in the couple group
        for (final parent in coupleGroup) {
          if (orientation == GraphOrientation.topToBottom) {
            parent.position =
                Offset(parent.position.dx + shift, parent.position.dy);
          } else {
            parent.position =
                Offset(parent.position.dx, parent.position.dy + shift);
          }
        }
      }

      // The total size of this subtree is the maximum of:
      // - couple group size (parents)
      // - total size of all children subtrees
      final totalSize = max(groupSize, trueChildrenSize);

      // Update the edge for this level
      levelEdges[level] = orientation == GraphOrientation.topToBottom
          ? x + totalSize
          : y + totalSize;

      // Return the total size needed for this entire family subtree
      return totalSize;
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

    // Process each root node (individuals with no parents)
    double currentPos = minPos; // Start with minimum position value

    for (final root in sortedRoots) {
      if (laidOut.contains(root)) continue; // Skip if already positioned

      // Layout this root's entire family tree and get its size
      final double subtreeSize = orientation == GraphOrientation.topToBottom
          ? layoutFamily(root, currentPos, 0, 0)
          : layoutFamily(root, 0, currentPos, 0);

      // Move to the position for the next root, adding extra spacing
      currentPos += subtreeSize + spacing * 3;
    }

    // Notify listeners that positions have been updated
    // setState?.call(() {
    //   nodes = nodes;
    // });

    // Center the graph if requested
    if (center) {
      centerGraph?.call();
    }
  }

  /// Sorts children by sibling groups to keep children of the same parents together
  ///
  /// This method organizes children in a logical order:
  /// 1. Children of the husband (male in couple) come first
  /// 2. Children with the same mother are grouped together
  /// 3. Children are ordered based on their mother's position in the couple
  /// 4. Children without a specified mother come before those with mothers
  ///
  /// [children]: List of child nodes to sort
  /// [coupleGroup]: List of parent nodes forming a family unit
  void sortChildrenBySiblingGroups(
      List<Node<E>> children, List<Node<E>> coupleGroup) {
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
  }
}
