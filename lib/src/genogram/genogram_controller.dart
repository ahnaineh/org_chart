import 'dart:math';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:org_chart/src/common/node.dart';
import 'package:org_chart/src/base/base_controller.dart';
import 'package:org_chart/src/genogram/genogram_constants.dart';

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

  /// Cache for generation level calculations
  final Map<String, int> _levelCache = {};

  /// Cached max size per generation level (main axis)
  final Map<int, double> _levelSizes = {};

  /// Cached offsets per generation level (main axis)
  final Map<int, double> _levelOffsets = {};

  /// Spacing between spouses in a couple group
  late double spouseSpacing;

  /// Creates a genogram controller with the specified parameters
  ///
  /// [items]: List of data items to display in the genogram
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
    super.spacing = GenogramConstants.defaultSpacing,
    super.runSpacing = GenogramConstants.defaultRunSpacing,
    super.orientation = GraphOrientation.topToBottom,
    required super.idProvider,
    super.sizeChangeAction = SizeChangeAction.ignore,
    super.sizeChangeThreshold = 0.0,
    super.preserveManualPositionsOnSizeChange = false,
    super.collisionSettings,
    required this.fatherProvider,
    required this.motherProvider,
    required this.spousesProvider,
    required this.genderProvider,
    double? spouseSpacing,
  }) {
    this.spouseSpacing = spouseSpacing ?? spacing;
    // Request initial layout after construction
    calculatePosition();
  }

  /// Clears all caches when items change
  // @override
  // set items(List<E> items) {
  //   _clearCaches();
  //   super.items = items;
  // }

  @override
  Size getSize() => contentSize;

  /// Clears all internal caches
  void _clearCaches() {
    _parentsCache.clear();
    _spousesCache.clear();
    _levelCache.clear();
  }

  @override
  void replaceAll(List<E> items,
      {bool recalculatePosition = true, bool centerGraph = false}) {
    _clearCaches();
    super.replaceAll(items,
        recalculatePosition: recalculatePosition, centerGraph: centerGraph);
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

  /// Returns the generation level (depth) of a node in the genogram
  ///
  /// Level is 1 for individuals with no parents, and increases by 1 for each
  /// generation based on the deepest parent chain.
  int getLevel(Node<E> node) {
    final String nodeId = idProvider(node.data);

    if (_levelCache.containsKey(nodeId)) {
      return _levelCache[nodeId]!;
    }

    int level = 1;
    final String? fatherId = fatherProvider(node.data);
    final String? motherId = motherProvider(node.data);

    int fatherLevel = 0;
    int motherLevel = 0;

    if (fatherId != null) {
      try {
        final fatherNode =
            nodes.firstWhere((n) => idProvider(n.data) == fatherId);
        fatherLevel = getLevel(fatherNode);
      } catch (_) {
        fatherLevel = 0;
      }
    }

    if (motherId != null) {
      try {
        final motherNode =
            nodes.firstWhere((n) => idProvider(n.data) == motherId);
        motherLevel = getLevel(motherNode);
      } catch (_) {
        motherLevel = 0;
      }
    }

    if (fatherLevel > 0 || motherLevel > 0) {
      level = 1 + max(fatherLevel, motherLevel);
    }

    _levelCache[nodeId] = level;
    return level;
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
    requestLayout(center: center);
  }

  double _levelOffsetFor(int level) => _levelOffsets[level] ?? 0;

  void _buildLevelMetrics() {
    _levelSizes.clear();
    _levelOffsets.clear();

    int maxLevel = 0;
    for (final node in nodes) {
      final int level = getLevel(node);
      final double mainSize = orientation == GraphOrientation.topToBottom
          ? node.size.height
          : node.size.width;
      final double current = _levelSizes[level] ?? 0;
      if (mainSize > current) {
        _levelSizes[level] = mainSize;
      }
      if (level > maxLevel) {
        maxLevel = level;
      }
    }

    double offset = 0;
    for (int level = 1; level <= maxLevel; level++) {
      _levelOffsets[level] = offset;
      offset += (_levelSizes[level] ?? 0) + runSpacing;
    }
  }

  @override
  void performLayout() {
    // Clear caches before recalculating positions
    _clearCaches();
    _buildLevelMetrics();

    // Track nodes that have been positioned to avoid duplicates
    final Set<Node<E>> laidOut = <Node<E>>{};

    // For each level (generation), track the rightmost edge (or bottommost edge for leftToRight)
    // to prevent overlaps
    final Map<int, double> levelEdges = {};

    // Minimum position to ensure nothing goes negative.
    // Keep this decoupled from spacing so spacing only affects gaps.
    const double minPos = 0;

    List<Node<E>> getChildrenForGroup(List<Node<E>> parents) {
      final parentIds = parents.map((p) => idProvider(p.data)).toSet();
      return nodes
          .where((child) =>
              parentIds.contains(fatherProvider(child.data)) ||
              parentIds.contains(motherProvider(child.data)))
          .toList();
    }

    double layoutFamily(Node<E> node, double crossAxisPos, int level) {
      crossAxisPos = max(crossAxisPos, minPos);

      if (laidOut.contains(node)) {
        return 0;
      }

      final List<Node<E>> coupleGroup = <Node<E>>[];

      if (isMale(node.data)) {
        coupleGroup.add(node);
        laidOut.add(node);

        final List<Node<E>> spouses = getSpouseList(node.data);
        for (final spouse in spouses) {
          laidOut.remove(spouse);
        }

        coupleGroup.addAll(spouses);
        laidOut.addAll(spouses);
      } else {
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

      if (coupleGroup.isEmpty) {
        return 0;
      }

      final int groupLevel = coupleGroup
          .map(getLevel)
          .fold<int>(1, (current, next) => max(current, next));
      final int desiredLevel = max(level + 1, groupLevel);
      level = desiredLevel - 1;

      final double mainAxisPos = _levelOffsetFor(desiredLevel);

      if (levelEdges.containsKey(level)) {
        crossAxisPos = max(crossAxisPos, levelEdges[level]! + spacing);
      } else {
        levelEdges[level] = crossAxisPos;
      }

      final int groupCount = coupleGroup.length;
      final double groupSpacing = groupCount > 1 ? spouseSpacing : spacing;
      double groupSize = 0;

      for (int i = 0; i < groupCount; i++) {
        final Node<E> person = coupleGroup[i];
        final double crossSize = orientation == GraphOrientation.topToBottom
            ? person.size.width
            : person.size.height;
        groupSize += crossSize;
        if (i < groupCount - 1) {
          groupSize += groupSpacing;
        }
      }

      double runningOffset = 0;
      for (int i = 0; i < groupCount; i++) {
        final Node<E> person = coupleGroup[i];
        final double crossSize = orientation == GraphOrientation.topToBottom
            ? person.size.width
            : person.size.height;

        if (orientation == GraphOrientation.topToBottom) {
          person.position = Offset(crossAxisPos + runningOffset, mainAxisPos);
        } else {
          person.position = Offset(mainAxisPos, crossAxisPos + runningOffset);
        }
        runningOffset += crossSize + groupSpacing;
      }

      List<Node<E>> children = getChildrenForGroup(coupleGroup)
          .where((child) => !laidOut.contains(child))
          .toList();

      sortChildrenBySiblingGroups(children, coupleGroup);

      if (children.isEmpty) {
        levelEdges[level] = crossAxisPos + groupSize;
        return groupSize;
      }

      double childrenTotalSize = 0;
      double childPos = crossAxisPos;

      for (final child in children) {
        final double subtreeSize = layoutFamily(child, childPos, level + 1);
        childrenTotalSize += subtreeSize;
        childPos += subtreeSize + spacing * 1.5;
      }

      final double trueChildrenSize = children.isNotEmpty
          ? childrenTotalSize - spacing * 0.5
          : 0;

      final double parentCenter = crossAxisPos + groupSize / 2;
      final double childrenCenter = crossAxisPos + trueChildrenSize / 2;
      final double shift = childrenCenter - parentCenter;

      if (children.isNotEmpty && trueChildrenSize > groupSize) {
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

      final double totalSize = max(groupSize, trueChildrenSize);
      levelEdges[level] = crossAxisPos + totalSize;
      return totalSize;
    }

    List<Node<E>> sortedRoots = [...roots];
    sortedRoots.sort((a, b) {
      if (isMale(a.data) && !isMale(b.data)) return -1;
      if (!isMale(a.data) && isMale(b.data)) return 1;
      return idProvider(a.data).compareTo(idProvider(b.data));
    });

    double currentPos = minPos;
    for (final root in sortedRoots) {
      if (laidOut.contains(root)) continue;
      final double subtreeSize = layoutFamily(root, currentPos, 0);
      currentPos += subtreeSize + spacing * 3;
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
