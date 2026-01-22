import 'package:flutter/widgets.dart';
import 'package:org_chart/src/common/node.dart';
import 'package:org_chart/src/common/quadtree_constants.dart';

/// A spatial data structure for efficient 2D range queries and collision detection
///
/// This QuadTree implementation is optimized for dynamic node insertion/removal
/// and provides O(log n) average case performance for spatial queries.
class QuadTree<E> {
  /// The maximum depth of this quadrant in the tree
  final int level;

  /// The boundary rectangle of this quadrant
  final Rect bounds;

  /// Nodes contained in this quadrant (if it's a leaf)
  List<Node<E>>? _nodes;

  /// Child quadrants (null if this is a leaf)
  List<QuadTree<E>?>? _children;

  /// Whether this quadrant has been subdivided
  bool get isSubdivided => _children != null;

  /// Whether this quadrant is a leaf (contains nodes directly)
  bool get isLeaf => _children == null;

  /// Number of nodes in this quadrant and all children
  int _totalNodeCount = 0;

  /// Creates a new QuadTree with the specified level and bounds
  ///
  /// [level] - The depth of this quadrant (0 = root)
  /// [bounds] - The rectangular boundary of this quadrant
  QuadTree({
    required this.level,
    required this.bounds,
  })  : assert(level >= 0, 'Level must be non-negative'),
        assert(bounds.width > 0 && bounds.height > 0,
            'Bounds must have positive dimensions') {
    _nodes = <Node<E>>[];
  }

  /// Inserts a node into the QuadTree
  ///
  /// Returns true if the node was successfully inserted, false otherwise
  bool insert(Node<E> node) {
    if (!_isNodeInBounds(node)) {
      return false;
    }

    _totalNodeCount++;

    // If we can hold more nodes and haven't subdivided, add to this quadrant
    if (isLeaf && _shouldAcceptNode()) {
      _nodes!.add(node);
      return true;
    }

    // If we haven't subdivided yet, do it now
    if (isLeaf) {
      _subdivide();
    }

    // Try to insert into appropriate child quadrant
    return _insertIntoChild(node);
  }

  /// Removes a node from the QuadTree
  ///
  /// Returns true if the node was found and removed, false otherwise
  bool remove(Node<E> node) {
    if (!_isNodeInBounds(node)) {
      return false;
    }

    if (isLeaf) {
      final removed = _nodes!.remove(node);
      if (removed) {
        _totalNodeCount--;
      }
      return removed;
    }

    // Try to remove from child quadrants
    for (final child in _children!) {
      if (child != null && child.remove(node)) {
        _totalNodeCount--;
        _tryMergeChildren();
        return true;
      }
    }

    return false;
  }

  /// Updates a node's position in the QuadTree
  ///
  /// This is more efficient than remove + insert for position updates
  bool updateNode(Node<E> node, Offset oldPosition) {
    // Remove from old position using a copy of the node with old position
    final currentPosition = node.position;
    node.position = oldPosition;
    final removed = remove(node);

    // Restore current position and insert
    node.position = currentPosition;
    if (removed) {
      return insert(node);
    }

    // If not found at old position, try inserting anyway
    return insert(node);
  }

  /// Returns all nodes within the specified circular range
  ///
  /// [center] - The center point of the search
  /// [radius] - The search radius
  List<Node<E>> getNodesInRange(Offset center, double radius) {
    final results = <Node<E>>[];
    final radiusSquared = radius * radius;

    _collectNodesInRange(center, radiusSquared, results);

    // Limit results to prevent memory issues
    if (results.length > QuadTreeConstants.maxQueryResults) {
      results.sort((a, b) {
        final distA = (a.position - center).distanceSquared;
        final distB = (b.position - center).distanceSquared;
        return distA.compareTo(distB);
      });
      return results.take(QuadTreeConstants.maxQueryResults).toList();
    }

    return results;
  }

  /// Returns all nodes within the specified rectangular bounds
  ///
  /// [queryBounds] - The rectangular area to search
  List<Node<E>> getNodesInBounds(Rect queryBounds) {
    final results = <Node<E>>[];
    _collectNodesInBounds(queryBounds, results);
    return results;
  }

  /// Returns all nodes that potentially overlap with the given node
  ///
  /// This is optimized for drag-and-drop collision detection
  List<Node<E>> getOverlappingNodes(Node<E> targetNode) {
    final nodeRect = _getNodeRect(targetNode);

    // Expand search area slightly to account for near-misses
    final searchBounds = nodeRect.inflate(targetNode.size.width * 0.1);

    return getNodesInBounds(searchBounds);
  }

  /// Clears all nodes from the QuadTree
  void clear() {
    _nodes?.clear();
    _children = null;
    _totalNodeCount = 0;
  }

  /// Returns the total number of nodes in this QuadTree
  int get nodeCount => _totalNodeCount;

  /// Returns statistics about the QuadTree structure
  QuadTreeStats getStats() {
    final stats = _StatsCollector();
    stats.maxDepth = level;
    _collectStats(this, stats);

    return QuadTreeStats(
      totalNodes: stats.nodeCount,
      leafQuadrants: stats.leafCount,
      maxDepth: stats.maxDepth,
      bounds: bounds,
    );
  }

  // ===== Private Methods =====

  /// Checks if a node intersects with this quadrant's bounds
  bool _isNodeInBounds(Node<E> node) {
    final nodeRect = _getNodeRect(node);
    return bounds.overlaps(nodeRect);
  }

  /// Determines if this quadrant should accept another node before subdividing
  bool _shouldAcceptNode() {
    return _nodes!.length < QuadTreeConstants.maxNodesPerQuadrant ||
        level >= QuadTreeConstants.maxDepth ||
        bounds.width < QuadTreeConstants.minQuadrantSize ||
        bounds.height < QuadTreeConstants.minQuadrantSize;
  }

  /// Subdivides this quadrant into four child quadrants
  void _subdivide() {
    if (isSubdivided) return;

    final halfWidth = bounds.width / 2;
    final halfHeight = bounds.height / 2;
    final x = bounds.left;
    final y = bounds.top;

    _children = List<QuadTree<E>?>.filled(4, null);

    // Create child quadrants: NW, NE, SW, SE
    _children![0] = QuadTree<E>(
      level: level + 1,
      bounds: Rect.fromLTWH(x, y, halfWidth, halfHeight),
    );
    _children![1] = QuadTree<E>(
      level: level + 1,
      bounds: Rect.fromLTWH(x + halfWidth, y, halfWidth, halfHeight),
    );
    _children![2] = QuadTree<E>(
      level: level + 1,
      bounds: Rect.fromLTWH(x, y + halfHeight, halfWidth, halfHeight),
    );
    _children![3] = QuadTree<E>(
      level: level + 1,
      bounds:
          Rect.fromLTWH(x + halfWidth, y + halfHeight, halfWidth, halfHeight),
    );

    // Redistribute existing nodes to children
    if (_nodes != null && _nodes!.isNotEmpty) {
      final nodesToRedistribute = List<Node<E>>.from(_nodes!);
      _nodes!.clear();

      for (final node in nodesToRedistribute) {
        _insertIntoChild(node);
      }
    }
  }

  /// Attempts to insert a node into a child quadrant
  bool _insertIntoChild(Node<E> node) {
    for (final child in _children!) {
      if (child != null && child._isNodeInBounds(node)) {
        if (child.insert(node)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Attempts to merge child quadrants if node count is below threshold
  void _tryMergeChildren() {
    if (isLeaf || _children == null) return;

    // Count total nodes in children
    int totalNodesInChildren = 0;
    for (final child in _children!) {
      if (child != null) {
        totalNodesInChildren += child._totalNodeCount;
      }
    }

    // If total nodes is small enough, merge children
    if (totalNodesInChildren <= QuadTreeConstants.maxNodesPerQuadrant) {
      _nodes = <Node<E>>[];

      for (final child in _children!) {
        if (child != null) {
          child._collectAllNodes(_nodes!);
        }
      }

      _children = null; // Remove subdivisions
    }
  }

  /// Collects all nodes from this quadrant and its children
  void _collectAllNodes(List<Node<E>> results) {
    if (isLeaf && _nodes != null) {
      results.addAll(_nodes!);
      return;
    }

    for (final child in _children!) {
      child?._collectAllNodes(results);
    }
  }

  void _collectNodesInRange(
    Offset center,
    double radiusSquared,
    List<Node<E>> results,
  ) {
    // Check if this quadrant intersects with the search circle
    if (!_intersectsCircle(center, radiusSquared)) return;

    if (isLeaf && _nodes != null) {
      for (final node in _nodes!) {
        final Offset nodeCenter =
            node.position + Offset(node.size.width / 2, node.size.height / 2);
        final double distSquared = (nodeCenter - center).distanceSquared;

        if (distSquared <= radiusSquared) {
          results.add(node);
        }
      }
      return;
    }

    // Recurse into children
    for (final child in _children!) {
      child?._collectNodesInRange(center, radiusSquared, results);
    }
  }

  void _collectNodesInBounds(
    Rect queryBounds,
    List<Node<E>> results,
  ) {
    if (!bounds.overlaps(queryBounds)) return;

    if (isLeaf && _nodes != null) {
      for (final node in _nodes!) {
        final nodeRect = _getNodeRect(node);
        if (queryBounds.overlaps(nodeRect)) {
          results.add(node);
        }
      }
      return;
    }

    for (final child in _children!) {
      child?._collectNodesInBounds(queryBounds, results);
    }
  }

  Rect _getNodeRect(Node<E> node) {
    return Rect.fromLTWH(
      node.position.dx,
      node.position.dy,
      node.size.width,
      node.size.height,
    );
  }

  bool _intersectsCircle(Offset center, double radiusSquared) {
    final double closestX = center.dx.clamp(bounds.left, bounds.right);
    final double closestY = center.dy.clamp(bounds.top, bounds.bottom);

    final double distanceX = center.dx - closestX;
    final double distanceY = center.dy - closestY;

    final double distanceSquared =
        distanceX * distanceX + distanceY * distanceY;
    return distanceSquared <= radiusSquared;
  }
}

class QuadTreeStats {
  final int totalNodes;
  final int leafQuadrants;
  final int maxDepth;
  final Rect bounds;

  QuadTreeStats({
    required this.totalNodes,
    required this.leafQuadrants,
    required this.maxDepth,
    required this.bounds,
  });
}

class _StatsCollector {
  int nodeCount = 0;
  int leafCount = 0;
  int maxDepth = 0;
}

void _collectStats<E>(QuadTree<E> tree, _StatsCollector stats) {
  if (tree.level > stats.maxDepth) {
    stats.maxDepth = tree.level;
  }

  if (tree.isLeaf) {
    stats.leafCount++;
    stats.nodeCount += tree._nodes?.length ?? 0;
    return;
  }

  for (final child in tree._children!) {
    if (child != null) {
      _collectStats(child, stats);
    }
  }
}
