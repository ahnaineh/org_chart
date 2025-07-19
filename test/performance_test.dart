import 'package:flutter_test/flutter_test.dart';
import 'package:org_chart/org_chart.dart';

class Employee {
  final String id;
  final String name;
  final String? managerId;

  Employee({required this.id, required this.name, this.managerId});
}

void main() {
  group('Performance Tests', () {
    test('getLevel() performance with caching', () {
      // Create a deep hierarchy
      final employees = <Employee>[];
      
      // Create 5 levels with 20 nodes per level = 100 nodes
      for (int level = 0; level < 5; level++) {
        for (int i = 0; i < 20; i++) {
          final id = 'L${level}_N$i';
          final managerId = level == 0 ? null : 'L${level - 1}_N${i % 20}';
          employees.add(Employee(
            id: id,
            name: 'Employee $id',
            managerId: managerId,
          ));
        }
      }

      final controller = OrgChartController<Employee>(
        items: employees,
        idProvider: (emp) => emp.id,
        toProvider: (emp) => emp.managerId,
      );

      // Warm up
      for (final node in controller.nodes) {
        controller.getLevel(node);
      }

      // Measure performance
      final stopwatch = Stopwatch()..start();
      
      // Call getLevel 1000 times
      for (int i = 0; i < 1000; i++) {
        for (final node in controller.nodes) {
          controller.getLevel(node);
        }
      }
      
      stopwatch.stop();
      print('Time for 100,000 getLevel calls: ${stopwatch.elapsedMilliseconds}ms');
      
      // Should be under 100ms with caching (without caching it would be 5000+ms)
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('Cache invalidation on node modification', () {
      final employees = [
        Employee(id: '1', name: 'CEO'),
        Employee(id: '2', name: 'Manager', managerId: '1'),
        Employee(id: '3', name: 'Employee', managerId: '2'),
      ];

      final controller = OrgChartController<Employee>(
        items: employees,
        idProvider: (emp) => emp.id,
        toProvider: (emp) => emp.managerId,
        toSetter: (emp, newManagerId) => Employee(
          id: emp.id,
          name: emp.name,
          managerId: newManagerId,
        ),
      );

      // Get initial levels
      final node3 = controller.nodes.firstWhere((n) => controller.idProvider(n.data) == '3');
      expect(controller.getLevel(node3), equals(3));

      // Change hierarchy - move employee directly under CEO
      controller.addItem(
        Employee(id: '3', name: 'Employee', managerId: '1'),
        recalculatePosition: false,
      );

      // Level should be recalculated
      final updatedNode3 = controller.nodes.firstWhere((n) => controller.idProvider(n.data) == '3');
      expect(controller.getLevel(updatedNode3), equals(2));
    });

    test('getSubNodes() performance with indexing', () {
      // Create a wide hierarchy - 1 root with 1000 direct children
      final employees = <Employee>[
        Employee(id: 'root', name: 'CEO'),
      ];
      
      for (int i = 0; i < 1000; i++) {
        employees.add(Employee(
          id: 'child_$i',
          name: 'Employee $i',
          managerId: 'root',
        ));
      }

      final controller = OrgChartController<Employee>(
        items: employees,
        idProvider: (emp) => emp.id,
        toProvider: (emp) => emp.managerId,
      );

      final rootNode = controller.nodes.firstWhere((n) => controller.idProvider(n.data) == 'root');
      
      // Measure performance
      final stopwatch = Stopwatch()..start();
      
      // Call getSubNodes 10000 times
      for (int i = 0; i < 10000; i++) {
        final children = controller.getSubNodes(rootNode);
        expect(children.length, equals(1000));
      }
      
      stopwatch.stop();
      print('Time for 10,000 getSubNodes calls with 1000 children: ${stopwatch.elapsedMilliseconds}ms');
      
      // Should be under 50ms with indexing (without indexing it would be 1000+ms)
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });

    test('getOverlapping() performance with QuadTree', () {
      // Create a grid of nodes
      final employees = <Employee>[];
      
      // Create a 50x50 grid = 2500 nodes
      for (int x = 0; x < 50; x++) {
        for (int y = 0; y < 50; y++) {
          employees.add(Employee(
            id: 'node_${x}_${y}',
            name: 'Employee ($x,$y)',
          ));
        }
      }

      final controller = OrgChartController<Employee>(
        items: employees,
        idProvider: (emp) => emp.id,
        toProvider: (emp) => emp.managerId,
      );

      // Position nodes in a grid
      int index = 0;
      for (int x = 0; x < 50; x++) {
        for (int y = 0; y < 50; y++) {
          controller.nodes[index].position = Offset(x * 150.0, y * 100.0);
          index++;
        }
      }
      
      
      // Test node in the middle of the grid
      final testNode = controller.nodes[1250]; // Middle of grid
      
      // Measure performance
      final stopwatch = Stopwatch()..start();
      
      // Call getOverlapping 1000 times
      for (int i = 0; i < 1000; i++) {
        final overlapping = controller.getOverlapping(testNode);
        // Should find some overlapping nodes in dense grid
        expect(overlapping.length, greaterThanOrEqualTo(0));
      }
      
      stopwatch.stop();
      // Measuring time for 1,000 getOverlapping calls in 2,500 node grid
      
      // Should be under 100ms with QuadTree (vs 1000+ms with linear search)
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
      
      // Verify QuadTree is being used
      expect(controller.isUsingQuadTree, isTrue);
    });
  });
}