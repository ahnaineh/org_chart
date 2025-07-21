import 'dart:math' as math;
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
  bool insert(Node<E> node, Size nodeSize) {
    if (!_isNodeInBounds(node, nodeSize)) {
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
    return _insertIntoChild(node, nodeSize);
  }

  /// Removes a node from the QuadTree
  ///
  /// Returns true if the node was found and removed, false otherwise
  bool remove(Node<E> node, Size nodeSize) {
    if (!_isNodeInBounds(node, nodeSize)) {
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
      if (child != null && child.remove(node, nodeSize)) {
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
  bool updateNode(Node<E> node, Size nodeSize, Offset oldPosition) {
    // Remove from old position using a copy of the node with old position
    final currentPosition = node.position;
    node.position = oldPosition;
    final removed = remove(node, nodeSize);

    // Restore current position and insert
    node.position = currentPosition;
    if (removed) {
      return insert(node, nodeSize);
    }

    // If not found at old position, try inserting anyway
    return insert(node, nodeSize);
  }

  /// Returns all nodes within the specified circular range
  ///
  /// [center] - The center point of the search
  /// [radius] - The search radius
  /// [nodeSize] - The size of nodes for intersection calculation
  List<Node<E>> getNodesInRange(Offset center, double radius, Size nodeSize) {
    final results = <Node<E>>[];
    final radiusSquared = radius * radius;

    _collectNodesInRange(center, radiusSquared, nodeSize, results);

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
  /// [nodeSize] - The size of nodes for intersection calculation
  List<Node<E>> getNodesInBounds(Rect queryBounds, Size nodeSize) {
    final results = <Node<E>>[];
    _collectNodesInBounds(queryBounds, nodeSize, results);
    return results;
  }

  /// Returns all nodes that potentially overlap with the given node
  ///
  /// This is optimized for drag-and-drop collision detection
  List<Node<E>> getOverlappingNodes(Node<E> targetNode, Size nodeSize) {
    final nodeRect = _getNodeRect(targetNode, nodeSize);

    // Expand search area slightly to account for near-misses
    final searchBounds = nodeRect.inflate(nodeSize.width * 0.1);

    return getNodesInBounds(searchBounds, nodeSize);
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
  bool _isNodeInBounds(Node<E> node, Size nodeSize) {
    final nodeRect = _getNodeRect(node, nodeSize);
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
        _insertIntoChild(node, Size.zero); // Size will be recalculated
      }
    }

    // Clear the nodes list since we're no longer a leaf
    _nodes = null;
  }

  /// Inserts a node into the appropriate child quadrant
  bool _insertIntoChild(Node<E> node, Size nodeSize) {
    if (!isSubdivided) return false;

    // Try to insert into each child that intersects with the node
    bool inserted = false;
    for (final child in _children!) {
      if (child != null && child._isNodeInBounds(node, nodeSize)) {
        if (child.insert(node, nodeSize)) {
          inserted = true;
          break; // Node should only be in one quadrant
        }
      }
    }

    return inserted;
  }

  /// Attempts to merge child quadrants if they collectively have few nodes
  void _tryMergeChildren() {
    if (isLeaf) return;

    var totalChildNodes = 0;
    final allChildNodes = <Node<E>>[];

    // Count nodes in all children
    for (final child in _children!) {
      if (child != null) {
        if (child.isLeaf) {
          totalChildNodes += child._nodes?.length ?? 0;
          allChildNodes.addAll(child._nodes ?? []);
        } else {
          return; // Don't merge if any child is subdivided
        }
      }
    }

    // Merge if total nodes are small enough
    if (totalChildNodes <= QuadTreeConstants.maxNodesPerQuadrant ~/ 2) {
      _children = null;
      _nodes = allChildNodes;
    }
  }

  /// Collects nodes within a circular range
  void _collectNodesInRange(
    Offset center,
    double radiusSquared,
    Size nodeSize,
    List<Node<E>> results,
  ) {
    // Quick bounds check
    final circleLeft = center.dx - math.sqrt(radiusSquared);
    final circleTop = center.dy - math.sqrt(radiusSquared);
    final circleRight = center.dx + math.sqrt(radiusSquared);
    final circleBottom = center.dy + math.sqrt(radiusSquared);

    final circleBounds =
        Rect.fromLTRB(circleLeft, circleTop, circleRight, circleBottom);

    if (!bounds.overlaps(circleBounds)) {
      return;
    }

    if (isLeaf) {
      for (final node in _nodes!) {
        final nodeCenter =
            node.position + Offset(nodeSize.width / 2, nodeSize.height / 2);
        final distanceSquared = (nodeCenter - center).distanceSquared;

        if (distanceSquared <= radiusSquared) {
          results.add(node);
        }
      }
    } else {
      for (final child in _children!) {
        child?._collectNodesInRange(center, radiusSquared, nodeSize, results);
      }
    }
  }

  /// Collects nodes within rectangular bounds
  void _collectNodesInBounds(
    Rect queryBounds,
    Size nodeSize,
    List<Node<E>> results,
  ) {
    if (!bounds.overlaps(queryBounds)) {
      return;
    }

    if (isLeaf) {
      for (final node in _nodes!) {
        final nodeRect = _getNodeRect(node, nodeSize);
        if (queryBounds.overlaps(nodeRect)) {
          results.add(node);
        }
      }
    } else {
      for (final child in _children!) {
        child?._collectNodesInBounds(queryBounds, nodeSize, results);
      }
    }
  }

  /// Gets the rectangular bounds of a node
  Rect _getNodeRect(Node<E> node, Size nodeSize) {
    return Rect.fromLTWH(
      node.position.dx,
      node.position.dy,
      nodeSize.width,
      nodeSize.height,
    );
  }

  /// Recursively collects statistics about the QuadTree
  static void _collectStats<E>(
    QuadTree<E> quadrant,
    _StatsCollector stats,
  ) {
    if (quadrant.isLeaf) {
      stats.leafCount++;
      stats.nodeCount += quadrant._nodes?.length ?? 0;
    } else {
      for (final child in quadrant._children!) {
        if (child != null) {
          stats.maxDepth = math.max(stats.maxDepth, child.level);
          _collectStats(child, stats);
        }
      }
    }
  }
}

/// Helper class for collecting statistics
class _StatsCollector {
  int leafCount = 0;
  int maxDepth = 0;
  int nodeCount = 0;
}

/// Statistics about a QuadTree's structure and performance
class QuadTreeStats {
  final int totalNodes;
  final int leafQuadrants;
  final int maxDepth;
  final Rect bounds;

  const QuadTreeStats({
    required this.totalNodes,
    required this.leafQuadrants,
    required this.maxDepth,
    required this.bounds,
  });

  /// Average nodes per leaf quadrant
  double get averageNodesPerLeaf =>
      leafQuadrants > 0 ? totalNodes / leafQuadrants : 0.0;

  /// Efficiency ratio (lower is better, ideal is close to maxNodesPerQuadrant)
  double get efficiencyRatio =>
      averageNodesPerLeaf / QuadTreeConstants.maxNodesPerQuadrant;

  @override
  String toString() {
    return 'QuadTreeStats('
        'nodes: $totalNodes, '
        'leafs: $leafQuadrants, '
        'depth: $maxDepth, '
        'avgPerLeaf: ${averageNodesPerLeaf.toStringAsFixed(1)}, '
        'efficiency: ${efficiencyRatio.toStringAsFixed(2)}'
        ')';
  }
}
