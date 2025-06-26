import 'package:flutter/widgets.dart';
import 'package:org_chart/src/common/node.dart';

/// Mixin for node querying utilities for OrgChartController
mixin NodeQueryMixin<E> {
  List<Node<E>> get nodes;
  String Function(E data) get idProvider;
  String? Function(E data) get toProvider;
  Size get boxSize;

  /// Returns the subnodes (children) of a given node
  List<Node<E>> getSubNodes(Node<E> node) {
    final nodeId = idProvider(node.data);
    return nodes
        .where((element) => toProvider(element.data) == nodeId)
        .toList();
  }

  /// Returns true if all nodes in the list are leaf nodes (no children or hidden)
  bool allLeaf(List<Node<E>> nodes) {
    return nodes
        .every((element) => getSubNodes(element).isEmpty || element.hideNodes);
  }

  /// Returns the level (depth) of a node in the tree
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

  /// Returns true if [dragged] is a subnode (descendant) of [target]
  bool isSubNode(Node<E> dragged, Node<E> target) {
    Node<E>? current = target;
    final draggedId = idProvider(dragged.data);

    while (current != null) {
      final currentToId = toProvider(current.data);

      if (currentToId == draggedId) {
        return true;
      }

      try {
        final matchingParents =
            nodes.where((element) => idProvider(element.data) == currentToId);
        current = matchingParents.isNotEmpty ? matchingParents.first : null;
      } catch (_) {
        break;
      }
    }

    return false;
  }

  /// Returns the parent node of a given node, or null if none
  Node<E>? getParent(Node<E> node) {
    final parentId = toProvider(node.data);
    if (parentId == null) return null;
    return nodes.where((n) => idProvider(n.data) == parentId).firstOrNull;
  }

  /// Returns true if the node or any of its parents are hidden
  bool isNodeHidden(Node<E> node) {
    Node<E>? parent = getParent(node);
    while (parent != null) {
      if (parent.hideNodes) return true;
      parent = getParent(parent);
    }
    return false;
  }

  /// Returns a list of nodes that overlap with the given node
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
}
