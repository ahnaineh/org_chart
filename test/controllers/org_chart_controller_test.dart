import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:org_chart/org_chart.dart';

class TestEmployee {
  final String id;
  final String name;
  final String? managerId;

  TestEmployee({required this.id, required this.name, this.managerId});
}

void main() {
  group('OrgChartController Tests', () {
    late OrgChartController<TestEmployee> controller;
    late List<TestEmployee> employees;

    setUp(() {
      employees = [
        TestEmployee(id: '1', name: 'CEO'),
        TestEmployee(id: '2', name: 'CTO', managerId: '1'),
        TestEmployee(id: '3', name: 'CFO', managerId: '1'),
        TestEmployee(id: '4', name: 'Dev Lead', managerId: '2'),
        TestEmployee(id: '5', name: 'Finance Lead', managerId: '3'),
      ];

      controller = OrgChartController<TestEmployee>(
        items: employees,
        idProvider: (emp) => emp.id,
        toProvider: (emp) => emp.managerId,
      );
    });

    test('Controller initialization', () {
      expect(controller.nodes.length, equals(5));
      expect(controller.orientation, equals(GraphOrientation.topToBottom));
      expect(controller.boxSize, equals(const Size(200, 100)));
    });

    test('Root nodes identification', () {
      final roots = controller.roots;
      expect(roots.length, equals(1));
      expect(controller.idProvider(roots.first.data), equals('1'));
    });

    test('Get subnodes', () {
      final ceoNode = controller.nodes.firstWhere(
        (n) => controller.idProvider(n.data) == '1',
      );
      final subnodes = controller.getSubNodes(ceoNode);
      
      expect(subnodes.length, equals(2));
      final subnodeIds = subnodes
          .map((n) => controller.idProvider(n.data))
          .toSet();
      expect(subnodeIds, equals({'2', '3'}));
    });

    test('Get level', () {
      final nodes = controller.nodes;
      
      final ceoNode = nodes.firstWhere(
        (n) => controller.idProvider(n.data) == '1',
      );
      final ctoNode = nodes.firstWhere(
        (n) => controller.idProvider(n.data) == '2',
      );
      final devLeadNode = nodes.firstWhere(
        (n) => controller.idProvider(n.data) == '4',
      );
      
      expect(controller.getLevel(ceoNode), equals(1));
      expect(controller.getLevel(ctoNode), equals(2));
      expect(controller.getLevel(devLeadNode), equals(3));
    });

    test('Add item', () {
      final newEmployee = TestEmployee(
        id: '6',
        name: 'New Dev',
        managerId: '4',
      );
      
      controller.addItem(newEmployee, recalculatePosition: false);
      
      expect(controller.nodes.length, equals(6));
      final newNode = controller.nodes.firstWhere(
        (n) => controller.idProvider(n.data) == '6',
      );
      expect(controller.toProvider(newNode.data), equals('4'));
    });

    test('Add item with existing ID replaces item', () {
      final updatedEmployee = TestEmployee(
        id: '3',
        name: 'Updated CFO',
        managerId: '1',
      );
      
      controller.addItem(updatedEmployee, recalculatePosition: false);
      
      expect(controller.nodes.length, equals(5));
      final updatedNode = controller.nodes.firstWhere(
        (n) => controller.idProvider(n.data) == '3',
      );
      expect(updatedNode.data.name, equals('Updated CFO'));
    });

    test('Add multiple items', () {
      final newEmployees = [
        TestEmployee(id: '6', name: 'Dev 1', managerId: '4'),
        TestEmployee(id: '7', name: 'Dev 2', managerId: '4'),
        TestEmployee(id: '8', name: 'Dev 3', managerId: '4'),
      ];
      
      controller.addItems(newEmployees, recalculatePosition: false);
      
      expect(controller.nodes.length, equals(8));
    });

    test('Remove item - unlinkDescendants', () {
      controller = OrgChartController<TestEmployee>(
        items: employees,
        idProvider: (emp) => emp.id,
        toProvider: (emp) => emp.managerId,
        toSetter: (emp, newManagerId) => TestEmployee(
          id: emp.id,
          name: emp.name,
          managerId: newManagerId,
        ),
      );
      
      controller.removeItem(
        '2',
        ActionOnNodeRemoval.unlinkDescendants,
        recalculatePosition: false,
      );
      
      // CTO removed, Dev Lead should now have no manager
      expect(controller.nodes.length, equals(4));
      final devLeadNode = controller.nodes.firstWhere(
        (n) => controller.idProvider(n.data) == '4',
      );
      expect(controller.toProvider(devLeadNode.data), isNull);
    });

    test('Remove item - connectDescendantsToParent', () {
      controller = OrgChartController<TestEmployee>(
        items: employees,
        idProvider: (emp) => emp.id,
        toProvider: (emp) => emp.managerId,
        toSetter: (emp, newManagerId) => TestEmployee(
          id: emp.id,
          name: emp.name,
          managerId: newManagerId,
        ),
      );
      
      controller.removeItem(
        '2',
        ActionOnNodeRemoval.connectDescendantsToParent,
        recalculatePosition: false,
      );
      
      // CTO removed, Dev Lead should now report to CEO
      expect(controller.nodes.length, equals(4));
      final devLeadNode = controller.nodes.firstWhere(
        (n) => controller.idProvider(n.data) == '4',
      );
      expect(controller.toProvider(devLeadNode.data), equals('1'));
    });

    test('Remove item - removeDescendants', () {
      controller.removeItem(
        '2',
        ActionOnNodeRemoval.removeDescendants,
        recalculatePosition: false,
      );
      
      // CTO and Dev Lead should both be removed
      expect(controller.nodes.length, equals(3));
      final remainingIds = controller.nodes
          .map((n) => controller.idProvider(n.data))
          .toSet();
      expect(remainingIds, equals({'1', '3', '5'}));
    });

    test('Clear items', () {
      controller.clearItems(recalculatePosition: false);
      expect(controller.nodes.isEmpty, isTrue);
    });

    test('Is subnode check', () {
      final ceoNode = controller.nodes.firstWhere(
        (n) => controller.idProvider(n.data) == '1',
      );
      final devLeadNode = controller.nodes.firstWhere(
        (n) => controller.idProvider(n.data) == '4',
      );
      
      expect(controller.isSubNode(ceoNode, devLeadNode), isTrue);
      expect(controller.isSubNode(devLeadNode, ceoNode), isFalse);
    });

    test('Orientation change', () {
      controller.orientation = GraphOrientation.leftToRight;
      expect(controller.orientation, equals(GraphOrientation.leftToRight));
    });

    test('Get parent', () {
      final devLeadNode = controller.nodes.firstWhere(
        (n) => controller.idProvider(n.data) == '4',
      );
      final parent = controller.getParent(devLeadNode);
      
      expect(parent, isNotNull);
      expect(controller.idProvider(parent!.data), equals('2'));
    });

    test('All leaf check', () {
      final leafNodes = controller.nodes.where((n) {
        final id = controller.idProvider(n.data);
        return id == '4' || id == '5';
      }).toList();
      
      final nonLeafNodes = controller.nodes.where((n) {
        final id = controller.idProvider(n.data);
        return id == '1' || id == '2';
      }).toList();
      
      expect(controller.allLeaf(leafNodes), isTrue);
      expect(controller.allLeaf(nonLeafNodes), isFalse);
    });
  });
}