import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:org_chart/src/common/node.dart';

void main() {
  group('Node Tests', () {
    test('Node creation with default values', () {
      final node = Node(data: 'test');
      
      expect(node.data, equals('test'));
      expect(node.position, equals(Offset.zero));
      expect(node.hideNodes, isFalse);
    });
    
    test('Node creation with custom values', () {
      final node = Node(
        data: 'test',
        position: const Offset(100, 200),
        hideNodes: true,
      );
      
      expect(node.data, equals('test'));
      expect(node.position, equals(const Offset(100, 200)));
      expect(node.hideNodes, isTrue);
    });
    
    test('Node distance calculation', () {
      final node1 = Node(data: 'node1', position: const Offset(0, 0));
      final node2 = Node(data: 'node2', position: const Offset(3, 4));
      
      final distance = node1.distance(node2);
      
      expect(distance.distance, equals(5.0));
      expect(distance.dx, equals(3.0));
      expect(distance.dy, equals(4.0));
    });
    
    test('Node distance calculation with same position', () {
      final node1 = Node(data: 'node1', position: const Offset(100, 100));
      final node2 = Node(data: 'node2', position: const Offset(100, 100));
      
      final distance = node1.distance(node2);
      
      expect(distance.distance, equals(0.0));
      expect(distance.dx, equals(0.0));
      expect(distance.dy, equals(0.0));
    });
  });
}