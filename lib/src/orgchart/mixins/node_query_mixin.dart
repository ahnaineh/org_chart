import 'package:flutter/widgets.dart';
import 'package:org_chart/src/common/node.dart';
import 'package:org_chart/src/common/quadtree.dart';
import 'package:org_chart/src/common/quadtree_constants.dart';

/// Mixin for node querying utilities for OrgChartController
mixin NodeQueryMixin<E> {
  List<Node<E>> get nodes;
  String Function(E data) get idProvider;
  String? Function(E data) get toProvider;
  Size get boxSize;

  /// Cache for node levels to avoid repeated calculations
  final Map<String, int> _levelCache = {};
  
  /// Index map for parent-child relationships - parentId -> List of child nodes
  final Map<String, List<Node<E>>> _childrenIndex = {};
  
  /// QuadTree for spatial indexing of nodes
  QuadTree<E>? _quadTree;
  

  /// Returns the subnodes (children) of a given node
  List<Node<E>> getSubNodes(Node<E> node) {
    final nodeId = idProvider(node.data);
    
    // Use index for O(1) lookup
    return _childrenIndex[nodeId] ?? [];
  }
  
  /// Rebuilds the children index - should be called when nodes are added/removed/modified
  void rebuildChildrenIndex() {
    _childrenIndex.clear();
    
    for (final node in nodes) {
      final parentId = toProvider(node.data);
      if (parentId != null) {
        _childrenIndex.putIfAbsent(parentId, () => []).add(node);
      }
    }
  }
  

  /// Returns true if all nodes in the list are leaf nodes (no children or hidden)
  bool allLeaf(List<Node<E>> nodes) {
    return nodes
        .every((element) => getSubNodes(element).isEmpty || element.hideNodes);
  }

  /// Returns the level (depth) of a node in the tree
  int getLevel(Node<E> node) {
    final nodeId = idProvider(node.data);
    
    // Check cache first
    if (_levelCache.containsKey(nodeId)) {
      return _levelCache[nodeId]!;
    }

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
    
    // Cache the result
    _levelCache[nodeId] = level;
    return level;
  }

  /// Clears the level cache - should be called when nodes are added/removed/modified
  @protected
  void clearLevelCache() {
    _levelCache.clear();
  }
  
  /// Rebuilds the QuadTree spatial index
  @protected
  void rebuildQuadTree() {
    if (nodes.isEmpty) {
      _quadTree = null;
      return;
    }
    
    // Calculate bounds for all nodes
    final bounds = _calculateNodeBounds();
    if (bounds == null) {
      _quadTree = null;
      return;
    }
    
    // Add padding to bounds
    final paddedBounds = bounds.inflate(QuadTreeConstants.boundsPadding);
    
    // Create new QuadTree
    _quadTree = QuadTree<E>(level: 0, bounds: paddedBounds);
    
    // Insert all nodes
    for (final node in nodes) {
      _quadTree!.insert(node, boxSize);
    }
  }

  @protected
  /// Clears all caches and rebuilds indexes
  void clearCachesAndRebuildIndexes() {
    clearLevelCache();
    rebuildChildrenIndex();
    rebuildQuadTree();
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
    // Use QuadTree if available and beneficial
    if (_quadTree != null && nodes.length > QuadTreeConstants.linearSearchThreshold) {
      return _getOverlappingWithQuadTree(node);
    }
    
    // Fallback to linear search for small datasets or when QuadTree unavailable
    return _getOverlappingLinear(node);
  }
  
  /// Fast overlap detection using QuadTree spatial indexing
  List<Node<E>> _getOverlappingWithQuadTree(Node<E> node) {
    final String nodeId = idProvider(node.data);
    
    // Get candidates from QuadTree
    final candidates = _quadTree!.getOverlappingNodes(node, boxSize);
    
    final overlapping = <Node<E>>[];
    
    for (final candidate in candidates) {
      final String candidateId = idProvider(candidate.data);
      if (nodeId != candidateId) {
        final offset = node.position - candidate.position;
        if (offset.dx.abs() < boxSize.width &&
            offset.dy.abs() < boxSize.height) {
          // Check if the node is hidden
          if (!isNodeHidden(candidate)) {
            overlapping.add(candidate);
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
  
  /// Linear search fallback for overlap detection
  List<Node<E>> _getOverlappingLinear(Node<E> node) {
    final overlapping = <Node<E>>[];
    final String nodeId = idProvider(node.data);

    for (final n in nodes) {
      final String nId = idProvider(n.data);
      if (nodeId != nId) {
        final offset = node.position - n.position;
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
  
  /// Updates a node's position in the QuadTree
  void updateNodePosition(Node<E> node, Offset oldPosition) {
    _quadTree?.updateNode(node, boxSize, oldPosition);
  }
  
  /// Calculates the bounding rectangle for all nodes
  Rect? _calculateNodeBounds() {
    if (nodes.isEmpty) return null;
    
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;
    
    for (final node in nodes) {
      final left = node.position.dx;
      final top = node.position.dy;
      final right = left + boxSize.width;
      final bottom = top + boxSize.height;
      
      minX = minX < left ? minX : left;
      minY = minY < top ? minY : top;
      maxX = maxX > right ? maxX : right;
      maxY = maxY > bottom ? maxY : bottom;
    }
    
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Returns whether QuadTree is currently being used for spatial queries
  bool get isUsingQuadTree => 
      _quadTree != null && nodes.length > QuadTreeConstants.linearSearchThreshold;
}
