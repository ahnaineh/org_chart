import 'package:flutter_test/flutter_test.dart';
import 'package:org_chart/org_chart.dart';

class PerfTestItem {
  final String id;
  final String name;
  final String? managerId;

  PerfTestItem({required this.id, required this.name, this.managerId});
}

void main() {
  group('Performance Optimization Tests', () {
    test('Level caching works correctly', () {
      // Create a deep hierarchy
      final items = <PerfTestItem>[];
      for (int i = 0; i < 100; i++) {
        items.add(PerfTestItem(
          id: i.toString(),
          name: 'Node $i',
          managerId: i == 0 ? null : (i - 1).toString(),
        ));
      }

      final controller = OrgChartController<PerfTestItem>(
        items: items,
        idProvider: (item) => item.id,
        toProvider: (item) => item.managerId,
      );

      // Get the deepest node
      final deepestNode = controller.nodes.firstWhere(
        (n) => controller.idProvider(n.data) == '99',
      );

      // First call should calculate and cache
      final stopwatch1 = Stopwatch()..start();
      final level1 = controller.getLevel(deepestNode);
      stopwatch1.stop();
      final firstCallTime = stopwatch1.elapsedMicroseconds;

      // Second call should be from cache (much faster)
      final stopwatch2 = Stopwatch()..start();
      final level2 = controller.getLevel(deepestNode);
      stopwatch2.stop();
      final secondCallTime = stopwatch2.elapsedMicroseconds;

      expect(level1, equals(100));
      expect(level2, equals(100));
      // Cache should make second call at least 10x faster
      expect(secondCallTime, lessThan(firstCallTime / 10));
    });

    test('Parent-child index provides O(1) lookups', () {
      // Create a wide hierarchy
      final items = <PerfTestItem>[
        PerfTestItem(id: 'root', name: 'Root'),
      ];
      
      // Add 1000 children to root
      for (int i = 0; i < 1000; i++) {
        items.add(PerfTestItem(
          id: 'child_$i',
          name: 'Child $i',
          managerId: 'root',
        ));
      }

      final controller = OrgChartController<PerfTestItem>(
        items: items,
        idProvider: (item) => item.id,
        toProvider: (item) => item.managerId,
      );

      final rootNode = controller.nodes.firstWhere(
        (n) => controller.idProvider(n.data) == 'root',
      );

      // Measure getSubNodes performance
      final stopwatch = Stopwatch()..start();
      final children = controller.getSubNodes(rootNode);
      stopwatch.stop();

      expect(children.length, equals(1000));
      // Should be very fast with indexing (under 1ms)
      expect(stopwatch.elapsedMilliseconds, lessThan(1));
    });

    test('Cache invalidation on node modification', () {
      final items = [
        PerfTestItem(id: '1', name: 'Root'),
        PerfTestItem(id: '2', name: 'Child', managerId: '1'),
        PerfTestItem(id: '3', name: 'Grandchild', managerId: '2'),
      ];

      final controller = OrgChartController<PerfTestItem>(
        items: items,
        idProvider: (item) => item.id,
        toProvider: (item) => item.managerId,
        toSetter: (item, newManagerId) => PerfTestItem(
          id: item.id,
          name: item.name,
          managerId: newManagerId,
        ),
      );

      final grandchildNode = controller.nodes.firstWhere(
        (n) => controller.idProvider(n.data) == '3',
      );

      // Initial level
      expect(controller.getLevel(grandchildNode), equals(3));

      // Move grandchild to report directly to root
      controller.addItem(
        PerfTestItem(id: '3', name: 'Grandchild', managerId: '1'),
        recalculatePosition: false,
      );

      // Level should be recalculated
      final updatedNode = controller.nodes.firstWhere(
        (n) => controller.idProvider(n.data) == '3',
      );
      expect(controller.getLevel(updatedNode), equals(2));
    });


    test('Multiple performance features work together', () {
      // Create a complex hierarchy
      final items = <PerfTestItem>[];
      items.add(PerfTestItem(id: '0', name: 'CEO'));
      
      int nodeId = 1;
      // Create 4 levels with increasing width
      for (int level = 1; level <= 4; level++) {
        final nodesInLevel = level * 10;
        final parentOffset = nodeId - nodesInLevel;
        
        for (int i = 0; i < nodesInLevel; i++) {
          final parentId = level == 1 
              ? '0' 
              : ((parentOffset + (i % (nodesInLevel ~/ level))).toString());
          items.add(PerfTestItem(
            id: nodeId.toString(),
            name: 'Node $nodeId',
            managerId: parentId,
          ));
          nodeId++;
        }
      }

      final controller = OrgChartController<PerfTestItem>(
        items: items,
        idProvider: (item) => item.id,
        toProvider: (item) => item.managerId,
      );

      // Test all optimizations are working
      final stopwatch = Stopwatch()..start();
      
      // Test level caching
      for (final node in controller.nodes) {
        controller.getLevel(node);
      }
      
      // Test parent-child lookups
      for (final node in controller.nodes.take(10)) {
        controller.getSubNodes(node);
      }
      
      // Test overlap detection
      for (final node in controller.nodes.take(10)) {
        controller.getOverlapping(node);
      }
      
      stopwatch.stop();
      
      // All operations should complete quickly
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('QuadTree spatial indexing performance', () {
      // Create a large grid of nodes (25x25 = 625 nodes, enough to test QuadTree)
      final items = <PerfTestItem>[];
      for (int x = 0; x < 25; x++) {
        for (int y = 0; y < 25; y++) {
          items.add(PerfTestItem(
            id: 'node_${x}_$y',
            name: 'Node ($x,$y)',
          ));
        }
      }

      final controller = OrgChartController<PerfTestItem>(
        items: items,
        idProvider: (item) => item.id,
        toProvider: (item) => item.managerId,
      );

      // Position nodes in a grid with spacing larger than box size (200x100) to avoid overlaps
      int index = 0;
      for (int x = 0; x < 25; x++) {
        for (int y = 0; y < 25; y++) {
          controller.nodes[index].position = Offset(x * 250.0, y * 150.0);
          index++;
        }
      }

      // Force QuadTree rebuild
      controller.rebuildQuadTree();
      
      // Verify QuadTree is being used
      expect(controller.isUsingQuadTree, isTrue);

      final testNode = controller.nodes[312]; // Middle of 25x25 grid (12,12)

      // Measure overlap detection performance
      final stopwatch = Stopwatch()..start();
      final overlapping = controller.getOverlapping(testNode);
      stopwatch.stop();

      // Should be very fast with QuadTree (under 5ms for 625 nodes)
      expect(stopwatch.elapsedMilliseconds, lessThan(5));
      
      // Should find no overlapping nodes in this grid layout
      expect(overlapping.isEmpty, isTrue);
      
      // Test with overlapping position
      testNode.position = testNode.position + const Offset(80, 45);
      final overlapping2 = controller.getOverlapping(testNode);
      expect(overlapping2.isNotEmpty, isTrue);
      
    });
  });
}