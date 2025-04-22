import 'package:flutter_test/flutter_test.dart';
import 'package:org_chart/src/controller.dart';
import 'package:org_chart/src/node.dart';

void main() {
  group('OrgChartController', () {
    late OrgChartController<ChartNode> controller;
    late List<ChartNode> chartNodes;

    setUp(() {
      chartNodes = [
        ChartNode(id: '1', parent: null, name: 'CEO'),
        ChartNode(id: '2', parent: '1', name: 'CTO'),
        ChartNode(id: '3', parent: '1', name: 'CFO'),
        ChartNode(id: '4', parent: '2', name: 'Dev Team Lead'),
        ChartNode(id: '5', parent: '2', name: 'QA Lead'),
        ChartNode(id: '6', parent: '3', name: 'Accountant'),
        ChartNode(id: '7', parent: '4', name: 'Senior Dev'),
        ChartNode(id: '8', parent: '4', name: 'Junior Dev'),
      ];

      controller = OrgChartController<ChartNode>(
        items: chartNodes,
        idProvider: (item) => item.id,
        toProvider: (item) => item.parent,
        toSetter: (item, newId) => item.parent = newId,
      );
    });

    test('Items setter replaces current items with new list', () {
      final newNodes = [
        ChartNode(id: '10', parent: null, name: 'Founder'),
        ChartNode(id: '11', parent: '10', name: 'Manager'),
      ];
      controller.items = newNodes;
      expect(controller.items.length, equals(newNodes.length));
      expect(controller.items.map((node) => node.id).toList(),
          containsAll(['10', '11']));
    });

    test('addItem adds a new node to items (happy path)', () {
      final initialCount = controller.items.length;
      final newNode = ChartNode(id: '9', parent: '1', name: 'Intern');
      controller.addItem(newNode);
      expect(controller.items.length, equals(initialCount + 1));
      expect(controller.items.any((node) => node.id == newNode.id), isTrue);
    });

    test('getSubNodes returns immediate children', () {
      // For node '1' (CEO), expect immediate children '2' (CTO) and '3' (CFO)
      var ceoNode =
          Node<ChartNode>(data: chartNodes.firstWhere((e) => e.id == '1'));
      final subNodes = controller.getSubNodes(ceoNode);
      final subIds = subNodes.map((node) => node.data.id).toList();
      expect(subIds, containsAll(['2', '3']));
    });

    test('getSubNodes returns empty list for a leaf node', () {
      // For node '5' (QA Lead), expect no children as it is a leaf
      var qaLeadNode =
          Node<ChartNode>(data: chartNodes.firstWhere((e) => e.id == '5'));
      final subNodes = controller.getSubNodes(qaLeadNode);
      expect(subNodes, isEmpty);
    });

    test('returns immediate parent node (happy path)', () {
      // For node '2', the immediate parent is '1'
      var node =
          Node<ChartNode>(data: chartNodes.firstWhere((e) => e.id == '2'));
      final parentNode = controller.getParent(node);
      expect(parentNode, isNotNull);
      expect(parentNode!.data.id, equals('1'));
    });

    test('returns null for a root node', () {
      // For node '1' (CEO), there is no parent
      var node =
          Node<ChartNode>(data: chartNodes.firstWhere((e) => e.id == '1'));
      final parentNode = controller.getParent(node);
      expect(parentNode, isNull);
    });

    group('Remove items', () {
      test('remove node without descendants with ActionOnNodeRemoval.unlink',
          () {
        controller.removeItem(chartNodes.last.id, ActionOnNodeRemoval.unlink);
        expect(controller.items.length, chartNodes.length - 1);
        expect(controller.items.map((e) => e.id).contains(chartNodes.last.id),
            false);
      });

      test(
          'remove node without descendants with ActionOnNodeRemoval.removeDescendants',
          () {
        controller.removeItem(
            chartNodes.last.id, ActionOnNodeRemoval.removeDescendants);
        expect(controller.items.length, chartNodes.length - 1);
        expect(controller.items.map((e) => e.id).contains(chartNodes.last.id),
            false);
      });

      test(
          'remove node without descendants with ActionOnNodeRemoval.connectToParent',
          () {
        controller.removeItem(
            chartNodes.last.id, ActionOnNodeRemoval.connectToParent);
        expect(controller.items.length, chartNodes.length - 1);
        expect(controller.items.map((e) => e.id).contains(chartNodes.last.id),
            false);
      });

      test('removes node using connectToParent', () {
        // Remove node '2' (CTO) and connect its children to its parent ('1').
        controller.removeItem('2', ActionOnNodeRemoval.connectToParent);
        // After removal, total nodes should be one less.
        expect(controller.items.length, chartNodes.length - 1);
        // The removed node should no longer exist.
        expect(controller.items.any((node) => node.id == '2'), isFalse);
        // Children of node '2' originally ('4' and '5') should now have '1' as their parent.
        final node4 = controller.items.firstWhere((node) => node.id == '4');
        final node5 = controller.items.firstWhere((node) => node.id == '5');
        expect(node4.parent, '1');
        expect(node5.parent, '1');
      });

      test('removes node using unlink', () {
        // Remove node '2' (CTO) and connect its children to its parent ('1').
        controller.removeItem('2', ActionOnNodeRemoval.unlink);
        // After removal, total nodes should be one less.
        expect(controller.items.length, chartNodes.length - 1);
        // The removed node should no longer exist.
        expect(controller.items.any((node) => node.id == '2'), isFalse);
        // Children of node '2' originally ('4' and '5') should now have '1' as their parent.
        final node4 = controller.items.firstWhere((node) => node.id == '4');
        final node5 = controller.items.firstWhere((node) => node.id == '5');
        expect(node4.parent, null);
        expect(node5.parent, null);
      });

      test('removes root node using removeDescendants', () {
        // Remove node '1' (CEO) and remove its childrens
        controller.removeItem('1', ActionOnNodeRemoval.removeDescendants);
        // After removal, total nodes should be one less.
        expect(controller.items.length, 0);
      });
    });
  });
}

class ChartNode {
  final String id;
  String? parent;
  final String name;

  ChartNode({
    required this.id,
    this.parent,
    required this.name,
  });
}
