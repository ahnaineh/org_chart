import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:org_chart/src/common/quadtree.dart';
import 'package:org_chart/src/common/quadtree_constants.dart';
import 'package:org_chart/src/common/node.dart';

/// Test model for QuadTree testing
class TestItem {
  final String id;
  final String name;

  TestItem({required this.id, required this.name});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'TestItem(id: $id, name: $name)';
}

void main() {
  group('QuadTree Core Functionality', () {
    late QuadTree<TestItem> quadTree;
    const bounds = Rect.fromLTWH(0, 0, 1000, 800);

    setUp(() {
      quadTree = QuadTree<TestItem>(level: 0, bounds: bounds);
    });

    test('should create QuadTree with correct initial state', () {
      expect(quadTree.level, equals(0));
      expect(quadTree.bounds, equals(bounds));
      expect(quadTree.isLeaf, isTrue);
      expect(quadTree.isSubdivided, isFalse);
      expect(quadTree.nodeCount, equals(0));
    });

    test('should insert nodes correctly', () {
      final node = Node<TestItem>(
        data: TestItem(id: '1', name: 'Test Node'),
        position: const Offset(100, 100),
      );

      final inserted = quadTree.insert(node);

      expect(inserted, isTrue);
      expect(quadTree.nodeCount, equals(1));
      expect(quadTree.isLeaf, isTrue);
    });

    test('should reject nodes outside bounds', () {
      final node = Node<TestItem>(
        data: TestItem(id: '1', name: 'Out of bounds'),
        position: const Offset(-100, -100), // Outside bounds
      );

      final inserted = quadTree.insert(node);

      expect(inserted, isFalse);
      expect(quadTree.nodeCount, equals(0));
    });

    test('should subdivide when capacity exceeded', () {
      // Insert nodes up to capacity
      for (int i = 0; i < QuadTreeConstants.maxNodesPerQuadrant; i++) {
        final node = Node<TestItem>(
          data: TestItem(id: i.toString(), name: 'Node $i'),
          position: Offset(50.0 + i * 10, 50.0 + i * 10),
        );
        quadTree.insert(node);
      }

      expect(quadTree.isLeaf, isTrue);
      expect(quadTree.nodeCount, equals(QuadTreeConstants.maxNodesPerQuadrant));

      // Insert one more to trigger subdivision
      final extraNode = Node<TestItem>(
        data: TestItem(id: 'extra', name: 'Extra Node'),
        position: const Offset(200, 200),
      );
      quadTree.insert(extraNode);

      expect(quadTree.isSubdivided, isTrue);
      expect(quadTree.isLeaf, isFalse);
      expect(quadTree.nodeCount,
          equals(QuadTreeConstants.maxNodesPerQuadrant + 1));
    });

    test('should remove nodes correctly', () {
      final node = Node<TestItem>(
        data: TestItem(id: '1', name: 'Test Node'),
        position: const Offset(100, 100),
      );

      quadTree.insert(node);
      expect(quadTree.nodeCount, equals(1));

      final removed = quadTree.remove(node);
      expect(removed, isTrue);
      expect(quadTree.nodeCount, equals(0));
    });

    test('should return false when removing non-existent node', () {
      final node = Node<TestItem>(
        data: TestItem(id: '1', name: 'Non-existent'),
        position: const Offset(100, 100),
      );

      final removed = quadTree.remove(node);
      expect(removed, isFalse);
      expect(quadTree.nodeCount, equals(0));
    });

    test('should clear all nodes', () {
      // Insert multiple nodes
      for (int i = 0; i < 5; i++) {
        final node = Node<TestItem>(
          data: TestItem(id: i.toString(), name: 'Node $i'),
          position: Offset(100.0 + i * 50, 100.0),
        );
        quadTree.insert(node);
      }

      expect(quadTree.nodeCount, equals(5));

      quadTree.clear();
      expect(quadTree.nodeCount, equals(0));
      expect(quadTree.isLeaf, isTrue);
    });
  });

  group('QuadTree Spatial Queries', () {
    late QuadTree<TestItem> quadTree;
    const nodeSize = Size(50, 30);
    const bounds = Rect.fromLTWH(0, 0, 1000, 800);

    setUp(() {
      quadTree = QuadTree<TestItem>(level: 0, bounds: bounds);

      // Create a grid of nodes for testing
      for (int x = 0; x < 10; x++) {
        for (int y = 0; y < 8; y++) {
          final node = Node<TestItem>(
            data: TestItem(id: '${x}_$y', name: 'Node $x,$y'),
            position: Offset(x * 100.0, y * 100.0),
          );
          quadTree.insert(node);
        }
      }
    });

    test('should find nodes in circular range', () {
      const center = Offset(250, 250);
      const radius = 150.0;

      final results = quadTree.getNodesInRange(center, radius);

      expect(results.isNotEmpty, isTrue);

      // Verify all results are within range
      for (final node in results) {
        final nodeCenter = node.position + const Offset(25, 15); // nodeSize/2
        final distance = (nodeCenter - center).distance;
        expect(distance, lessThanOrEqualTo(radius));
      }
    });

    test('should find nodes in rectangular bounds', () {
      const queryBounds = Rect.fromLTWH(150, 150, 300, 200);

      final results = quadTree.getNodesInBounds(queryBounds);

      expect(results.isNotEmpty, isTrue);

      // Verify all results intersect with query bounds
      for (final node in results) {
        final nodeRect = Rect.fromLTWH(
          node.position.dx,
          node.position.dy,
          nodeSize.width,
          nodeSize.height,
        );
        expect(queryBounds.overlaps(nodeRect), isTrue);
      }
    });

    test('should find overlapping nodes for drag detection', () {
      final targetNode = Node<TestItem>(
        data: TestItem(id: 'target', name: 'Target'),
        position: const Offset(205, 105), // Slightly overlapping with grid
      );

      final overlapping = quadTree.getOverlappingNodes(targetNode);

      expect(overlapping.isNotEmpty, isTrue);

      // Should find nearby nodes
      expect(overlapping.any((n) => n.data.id == '2_1'), isTrue);
    });

    test('should handle empty regions gracefully', () {
      const center = Offset(1500, 1500); // Outside bounds
      const radius = 100.0;

      final results = quadTree.getNodesInRange(center, radius);

      expect(results.isEmpty, isTrue);
    });

    test('should limit results to prevent memory issues', () {
      // Create a dense QuadTree
      final denseQuadTree = QuadTree<TestItem>(level: 0, bounds: bounds);

      // Insert many nodes in a small area
      for (int i = 0; i < QuadTreeConstants.maxQueryResults + 50; i++) {
        final node = Node<TestItem>(
          data: TestItem(id: i.toString(), name: 'Dense $i'),
          position: Offset(500.0 + (i % 10) * 5, 400.0 + (i ~/ 10) * 5),
        );
        denseQuadTree.insert(node);
      }

      const center = Offset(525, 425);
      const radius = 200.0;

      final results = denseQuadTree.getNodesInRange(center, radius);

      expect(
          results.length, lessThanOrEqualTo(QuadTreeConstants.maxQueryResults));
    });
  });

  group('QuadTree Node Updates', () {
    late QuadTree<TestItem> quadTree;
    const bounds = Rect.fromLTWH(0, 0, 1000, 800);

    setUp(() {
      quadTree = QuadTree<TestItem>(level: 0, bounds: bounds);
    });

    test('should update node position correctly', () {
      final node = Node<TestItem>(
        data: TestItem(id: '1', name: 'Movable Node'),
        position: const Offset(100, 100),
      );

      quadTree.insert(node);
      expect(quadTree.nodeCount, equals(1));

      // Update position
      const oldPosition = Offset(100, 100);
      node.position = const Offset(300, 300);

      final updated = quadTree.updateNode(node, oldPosition);
      expect(updated, isTrue);
      expect(quadTree.nodeCount, equals(1));

      // Verify node is in new position
      final results = quadTree.getNodesInBounds(
        const Rect.fromLTWH(290, 290, 60, 40),
      );
      expect(results.length, equals(1));
      expect(results.first.data.id, equals('1'));
    });

    test('should handle update when old position not found', () {
      final node = Node<TestItem>(
        data: TestItem(id: '1', name: 'New Node'),
        position: const Offset(100, 100),
      );

      // Try to update without inserting first
      const oldPosition = Offset(50, 50);
      final updated = quadTree.updateNode(node, oldPosition);

      // Should still insert the node at new position
      expect(updated, isTrue);
      expect(quadTree.nodeCount, equals(1));
    });
  });

  group('QuadTree Statistics and Performance', () {
    late QuadTree<TestItem> quadTree;
    const bounds = Rect.fromLTWH(0, 0, 1000, 800);

    setUp(() {
      quadTree = QuadTree<TestItem>(level: 0, bounds: bounds);
    });

    test('should provide accurate statistics', () {
      // Insert nodes to force subdivision using a grid pattern that ensures all fit in bounds
      const gridSize = 5; // 5x5 = 25 nodes
      for (int x = 0; x < gridSize; x++) {
        for (int y = 0; y < gridSize; y++) {
          final node = Node<TestItem>(
            data: TestItem(id: '${x}_$y', name: 'Node $x,$y'),
            position: Offset(
                x * 150.0 + 50, y * 120.0 + 50), // Safe positions within bounds
          );
          final inserted = quadTree.insert(node);
          expect(inserted, isTrue, reason: 'Node at $x,$y should be inserted');
        }
      }

      final stats = quadTree.getStats();

      expect(stats.totalNodes, equals(25));
      expect(stats.maxDepth, greaterThan(0));
      expect(stats.leafQuadrants, greaterThan(0));
      expect(stats.bounds, equals(bounds));
    });

    test('should handle statistics for empty QuadTree', () {
      final stats = quadTree.getStats();

      expect(stats.totalNodes, equals(0));
      expect(stats.maxDepth, equals(0));
      expect(stats.leafQuadrants,
          greaterThan(0)); // Root is always a leaf when empty
    });

    test('should maintain performance with many nodes', () {
      const nodeCount = 1000;
      final stopwatch = Stopwatch()..start();

      // Insert many nodes
      for (int i = 0; i < nodeCount; i++) {
        final node = Node<TestItem>(
          data: TestItem(id: i.toString(), name: 'Node $i'),
          position: Offset(
            (i % 50) * 20.0,
            (i ~/ 50) * 20.0,
          ),
        );
        quadTree.insert(node);
      }

      final insertTime = stopwatch.elapsedMilliseconds;
      stopwatch.reset();

      // Perform range queries
      for (int i = 0; i < 100; i++) {
        final center = Offset(i * 10.0, i * 8.0);
        quadTree.getNodesInRange(center, 100);
      }

      final queryTime = stopwatch.elapsedMilliseconds;
      stopwatch.stop();

      // Performance assertions (generous to account for test environment variability)
      expect(insertTime,
          lessThan(1000)); // Should insert 1000 nodes in under 1 second
      expect(queryTime,
          lessThan(500)); // Should perform 100 queries in under 0.5 seconds

      expect(quadTree.nodeCount, equals(nodeCount));
    });
  });

  group('QuadTree Edge Cases and Error Handling', () {
    test('should reject invalid bounds', () {
      expect(
        () => QuadTree<TestItem>(
            level: 0, bounds: const Rect.fromLTWH(0, 0, 0, 100)),
        throwsAssertionError,
      );

      expect(
        () => QuadTree<TestItem>(
            level: 0, bounds: const Rect.fromLTWH(0, 0, 100, 0)),
        throwsAssertionError,
      );
    });

    test('should reject negative level', () {
      expect(
        () => QuadTree<TestItem>(
            level: -1, bounds: const Rect.fromLTWH(0, 0, 100, 100)),
        throwsAssertionError,
      );
    });

    test('should respect maximum depth', () {
      final quadTree = QuadTree<TestItem>(
        level: QuadTreeConstants.maxDepth,
        bounds: const Rect.fromLTWH(0, 0, 100, 100),
      );

      // Try to insert more nodes than capacity at max depth
      for (int i = 0; i <= QuadTreeConstants.maxNodesPerQuadrant + 5; i++) {
        final node = Node<TestItem>(
          data: TestItem(id: i.toString(), name: 'Node $i'),
          position: Offset(i * 5.0, i * 5.0),
        );
        quadTree.insert(node);
      }

      // Should remain a leaf (not subdivide) at max depth
      expect(quadTree.isLeaf, isTrue);
      expect(quadTree.level, equals(QuadTreeConstants.maxDepth));
    });

    test('should respect minimum quadrant size', () {
      final quadTree = QuadTree<TestItem>(
        level: 0,
        bounds:
            const Rect.fromLTWH(0, 0, 30, 30), // Smaller than minQuadrantSize
      );

      // Try to insert more nodes than capacity
      for (int i = 0; i <= QuadTreeConstants.maxNodesPerQuadrant + 2; i++) {
        final node = Node<TestItem>(
          data: TestItem(id: i.toString(), name: 'Node $i'),
          position: Offset(i * 2.0, i * 2.0),
        );
        quadTree.insert(node);
      }

      // Should remain a leaf (not subdivide) due to minimum size constraint
      expect(quadTree.isLeaf, isTrue);
    });

    test('should handle nodes at exact boundaries', () {
      const bounds = Rect.fromLTWH(0, 0, 100, 100);
      final quadTree = QuadTree<TestItem>(level: 0, bounds: bounds);

      // Node exactly at boundary
      final boundaryNode = Node<TestItem>(
        data: TestItem(id: 'boundary', name: 'Boundary Node'),
        position: const Offset(100, 100), // Exactly at right-bottom corner
      );

      final inserted = quadTree.insert(boundaryNode);
      // Should be rejected as it's outside bounds (boundary is exclusive)
      expect(inserted, isFalse);

      // Node just inside boundary
      final insideNode = Node<TestItem>(
        data: TestItem(id: 'inside', name: 'Inside Node'),
        position: const Offset(90, 90),
      );

      final insertedInside = quadTree.insert(insideNode);
      expect(insertedInside, isTrue);
    });
  });
}
