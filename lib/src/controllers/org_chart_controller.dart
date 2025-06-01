import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:org_chart/src/common/node.dart';
import 'package:org_chart/src/controllers/base_controller.dart';

enum ActionOnNodeRemoval {
  unlinkDescendants,
  connectDescendantsToParent,
  removeDescendants
}

/// Controller specifically for organizational charts
class OrgChartController<E> extends BaseGraphController<E> {
  // /// Get the current orientation of the chart
  // OrgChartOrientation get orientation => _orientation;

  /// Get the "to" ID of a node
  String? Function(E data) toProvider;

  /// replace the item with updated to ID
  E Function(E data, String? newID)? toSetter;

  /// Number of columns to arrange leaf nodes in (default: 2)
  int leafColumns;

  OrgChartController({
    required super.items,
    super.boxSize,
    super.spacing,
    super.runSpacing,
    super.orientation = GraphOrientation.topToBottom,
    required super.idProvider,
    required this.toProvider,
    this.toSetter,
    this.leafColumns = 4,
  });

  // Node-related methods
  @override
  List<Node<E>> get roots =>
      nodes.where((node) => getLevel(node) == 1).toList();

  List<Node<E>> getSubNodes(Node<E> node) {
    final nodeId = idProvider(node.data);
    return nodes
        .where((element) => toProvider(element.data) == nodeId)
        .toList();
  }

  bool allLeaf(List<Node<E>> nodes) {
    return nodes
        .every((element) => getSubNodes(element).isEmpty || element.hideNodes);
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
        current = nodes.firstWhere((n) => idProvider(n.data) == currentToId);
        level++;
      } catch (_) {
        break;
      }
    }
    return level;
  }

  bool isSubNode(Node<E> dragged, Node<E> target) {
    E? current = target.data;
    final draggedId = idProvider(dragged.data);

    while (current != null) {
      final currentToId = toProvider(current);

      if (currentToId == draggedId) {
        return true;
      }

      try {
        final matchingParents =
            items.where((element) => idProvider(element) == currentToId);
        current = matchingParents.isNotEmpty ? matchingParents.first : null;
      } catch (_) {
        break;
      }
    }

    return false;
  }

  /// Remove an item from the chart
  void removeItem(String? id, ActionOnNodeRemoval action) {
    if (action == ActionOnNodeRemoval.unlinkDescendants ||
        action == ActionOnNodeRemoval.connectDescendantsToParent) {
      assert(toSetter != null,
          "toSetter is not provided, you can't use this function without providing a toSetter");
    }

    final nodeToRemove =
        nodes.firstWhere((element) => idProvider(element.data) == id);

    final subnodes =
        nodes.where((element) => toProvider(element.data) == id).toList();

    for (Node<E> node in subnodes) {
      switch (action) {
        case ActionOnNodeRemoval.unlinkDescendants:
          addItem(toSetter!(node.data, null));

          break;
        case ActionOnNodeRemoval.connectDescendantsToParent:
          addItem(toSetter!(node.data, toProvider(nodeToRemove.data)));
          break;
        case ActionOnNodeRemoval.removeDescendants:
          removeNodeAndDescendants(nodes, node);
          break;
      }
    }

    nodes.remove(nodeToRemove);
    calculatePosition();
  }

  @override
  void calculatePosition({bool center = true}) {
    double offset = 0;
    for (Node<E> node in roots) {
      offset += _calculateNodePositions(
        node,
        offset: orientation == GraphOrientation.topToBottom
            ? Offset(offset, 0)
            : Offset(0, offset),
      );
    }

    setState?.call(() {});
    if (center) {
      centerGraph?.call();
    }
  }

  Size _calculateMaxSize(Node<E> node, Size currentSize) {
    // Update current max size with this node's position
    Size updatedSize = Size(
      math.max(currentSize.width, node.position.dx),
      math.max(currentSize.height, node.position.dy),
    );

    // If nodes are not hidden, recursively check children
    if (!node.hideNodes) {
      List<Node<E>> children = getSubNodes(node);
      for (Node<E> child in children) {
        updatedSize = _calculateMaxSize(child, updatedSize);
      }
    }

    return updatedSize;
  }

  @override
  Size getSize({Size size = const Size(0, 0)}) {
    // Start from root nodes
    for (Node<E> root in roots) {
      size = _calculateMaxSize(root, size);
    }

    // Add box dimensions to get final size
    return size + Offset(boxSize.width, boxSize.height);
  }

  // Private position calculation methods
  double _calculateNodePositions(Node<E> node,
      {Offset offset = const Offset(0, 0)}) {
    return orientation == GraphOrientation.topToBottom
        ? _calculatePositionsTopToBottom(node, offset: offset)
        : _calculatePositionsLeftToRight(node, offset: offset);
  }

  double _calculatePositionsTopToBottom(Node<E> node,
      {Offset offset = const Offset(0, 0)}) {
    List<Node<E>> subNodes = getSubNodes(node);

    if (allLeaf(subNodes)) {
      return _positionLeafNodesTopToBottom(node, subNodes, offset);
    } else {
      return _positionNonLeafNodesTopToBottom(node, subNodes, offset);
    }
  }

  double _calculatePositionsLeftToRight(Node<E> node,
      {Offset offset = const Offset(0, 0)}) {
    List<Node<E>> subNodes = getSubNodes(node);

    if (allLeaf(subNodes)) {
      return _positionLeafNodesLeftToRight(node, subNodes, offset);
    } else {
      return _positionNonLeafNodesLeftToRight(node, subNodes, offset);
    }
  }

  // Position calculations for leaf nodes (nodes without hidden children)
  double _positionLeafNodesTopToBottom(
      Node<E> node, List<Node<E>> subNodes, Offset offset) {
    // Handle empty subNodes case
    if (subNodes.isEmpty) {
      node.position = offset +
          Offset(
            0,
            (getLevel(node) - 1) * (boxSize.height + runSpacing),
          );
      return boxSize.width + spacing;
    }

    // Use minimum of available children and leafColumns
    int effectiveColumns = math.min(subNodes.length, leafColumns);

    // Position subnodes in a grid pattern with the specified columns
    for (var i = 0; i < subNodes.length; i++) {
      int row = i ~/ effectiveColumns;
      int col = i % effectiveColumns;

      subNodes[i].position = offset +
          Offset(
            col * (boxSize.width + spacing),
            (getLevel(subNodes[i]) - 1 + row) * (boxSize.height + runSpacing),
          );
    }

    // Calculate width of the last row (which may be different)
    int itemsInLastRow = subNodes.length % effectiveColumns == 0
        ? effectiveColumns
        : subNodes.length % effectiveColumns;
    double lastRowWidth =
        itemsInLastRow * boxSize.width + (itemsInLastRow - 1) * spacing;

    // Full row width
    double fullRowWidth =
        effectiveColumns * boxSize.width + (effectiveColumns - 1) * spacing;

    // The width is the maximum of the full row width and the last row width
    double maxRowWidth = math.max(fullRowWidth, lastRowWidth);

    // Center the parent node above its children
    node.position = offset +
        Offset(
          (maxRowWidth - boxSize.width) / 2,
          (getLevel(node) - 1) * (boxSize.height + runSpacing),
        );

    // Return the total width needed for this subtree
    return maxRowWidth + spacing;
  }

  // Position calculations for non-leaf nodes (nodes with visible children)
  double _positionNonLeafNodesTopToBottom(
      Node<E> node, List<Node<E>> subNodes, Offset offset) {
    // If no subnodes or they're hidden, return minimal width
    if (subNodes.isEmpty || node.hideNodes) {
      node.position = offset +
          Offset(
            0,
            (getLevel(node) - 1) * (boxSize.height + runSpacing),
          );
      return boxSize.width + spacing;
    }

    // Calculate positions for all subnodes
    double totalWidth = 0;
    List<double> nodeWidths = [];

    for (var i = 0; i < subNodes.length; i++) {
      double nodeWidth = _calculatePositionsTopToBottom(
        subNodes[i],
        offset: offset + Offset(totalWidth, 0),
      );
      nodeWidths.add(nodeWidth);
      totalWidth += nodeWidth;
    }

    // Center parent above children
    if (subNodes.length == 1) {
      // For single child, align directly above
      node.position = Offset(
        subNodes.first.position.dx,
        (getLevel(node) - 1) * (boxSize.height + runSpacing),
      );
    } else {
      // For multiple children, center above the group
      double leftmostX = subNodes.first.position.dx;
      double rightmostX = subNodes.last.position.dx + boxSize.width;
      double centerX = (leftmostX + rightmostX) / 2 - boxSize.width / 2;

      node.position = Offset(
        centerX,
        (getLevel(node) - 1) * (boxSize.height + runSpacing),
      );
    }

    return totalWidth;
  }

  // Position calculations for leaf nodes in left-to-right orientation
  double _positionLeafNodesLeftToRight(
      Node<E> node, List<Node<E>> subNodes, Offset offset) {
    // Handle empty subNodes case
    if (subNodes.isEmpty) {
      node.position = offset +
          Offset(
            (getLevel(node) - 1) * (boxSize.width + runSpacing),
            0,
          );
      return boxSize.height + spacing;
    }

    // Use minimum of available children and leafColumns
    int effectiveColumns = math.min(subNodes.length, leafColumns);

    // Position subnodes in a grid pattern with the specified rows
    for (var i = 0; i < subNodes.length; i++) {
      int col = i ~/ effectiveColumns;
      int row = i % effectiveColumns;

      subNodes[i].position = offset +
          Offset(
            (getLevel(subNodes[i]) - 1 + col) * (boxSize.width + runSpacing),
            row * (boxSize.height + spacing),
          );
    }

    // Calculate height of the last column (which may be different)
    int itemsInLastCol = subNodes.length % effectiveColumns == 0
        ? effectiveColumns
        : subNodes.length % effectiveColumns;
    double lastColHeight =
        itemsInLastCol * boxSize.height + (itemsInLastCol - 1) * spacing;

    // Full column height
    double fullColHeight =
        effectiveColumns * boxSize.height + (effectiveColumns - 1) * spacing;

    // The height is the maximum of the full column height and the last column height
    double maxColHeight = math.max(fullColHeight, lastColHeight);

    // Center the parent node to the left of its children
    node.position = offset +
        Offset(
          (getLevel(node) - 1) * (boxSize.width + runSpacing),
          (maxColHeight - boxSize.height) / 2,
        );

    // Return the total height needed for this subtree
    return maxColHeight + spacing;
  }

  // Position calculations for non-leaf nodes in left-to-right orientation
  double _positionNonLeafNodesLeftToRight(
      Node<E> node, List<Node<E>> subNodes, Offset offset) {
    // If no subnodes or they're hidden, return minimal height
    if (subNodes.isEmpty || node.hideNodes) {
      node.position = offset +
          Offset(
            (getLevel(node) - 1) * (boxSize.width + runSpacing),
            0,
          );
      return boxSize.height + spacing;
    }

    // Calculate positions for all subnodes
    double totalHeight = 0;
    List<double> nodeHeights = [];

    for (var i = 0; i < subNodes.length; i++) {
      double nodeHeight = _calculatePositionsLeftToRight(
        subNodes[i],
        offset: offset + Offset(0, totalHeight),
      );
      nodeHeights.add(nodeHeight);
      totalHeight += nodeHeight;
    }

    // Center parent to the left of children
    if (subNodes.length == 1) {
      // For single child, align directly to the left
      node.position = Offset(
        (getLevel(node) - 1) * (boxSize.width + runSpacing),
        subNodes.first.position.dy,
      );
    } else {
      // For multiple children, center to the left of the group
      double topmostY = subNodes.first.position.dy;
      double bottommostY = subNodes.last.position.dy + boxSize.height;
      double centerY = (topmostY + bottommostY) / 2 - boxSize.height / 2;

      node.position = Offset(
        (getLevel(node) - 1) * (boxSize.width + runSpacing),
        centerY,
      );
    }

    return totalHeight;
  }

  /// Removes a node and all its descendants from the list of nodes
  void removeNodeAndDescendants(List<Node<E>> nodes, Node<E> nodeToRemove) {
    Set<Node<E>> nodesToRemove = {};

    void collectDescendantNodes(Node<E> currentNode) {
      nodesToRemove.add(currentNode);

      final nodeId = idProvider(currentNode.data);
      final subnodes =
          nodes.where((element) => toProvider(element.data) == nodeId);

      for (final node in subnodes) {
        collectDescendantNodes(node);
      }
    }

    collectDescendantNodes(nodeToRemove);
    nodes.removeWhere((node) => nodesToRemove.contains(node));
  }

  Node<E>? getParent(Node<E> node) {
    final parentId = toProvider(node.data);
    if (parentId == null) return null;
    return nodes.where((n) => idProvider(n.data) == parentId).firstOrNull;
  }

  @override
  List<Node<E>> getOverlapping(Node<E> node) {
    List<Node<E>> overlapping = [];
    final String nodeId = idProvider(node.data);

    for (Node<E> n in nodes) {
      final String nId = idProvider(n.data);
      if (nodeId != nId) {
        Offset offset = node.position - n.position;
        if (offset.dx.abs() < boxSize.width &&
            offset.dy.abs() < boxSize.height) {
          // Check if the node is hidden
          if (!isNodeHidden(n)) {
            overlapping.add(n);
          }
        }
      }
    }

    overlapping.sort((a, b) => a
        .distance(node)
        .distanceSquared
        .compareTo(b.distance(node).distanceSquared));

    return overlapping;
  }

  bool isNodeHidden(Node<E> node) {
    // Check if any parent nodes are hidden
    Node<E>? parent = getParent(node);
    while (parent != null) {
      if (parent.hideNodes) return true;
      parent = getParent(parent);
    }
    return false;
  }
}
