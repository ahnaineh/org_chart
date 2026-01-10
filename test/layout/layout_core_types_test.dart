import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:org_chart/org_chart.dart';

class _OrgChartRowEngine implements OrgChartLayoutEngine {
  @override
  LayoutResult layout(LayoutRequest<OrgChartLayoutGraph> request) {
    final positions = <String, Offset>{};
    var x = 0.0;

    for (final entry in request.graph.nodes.entries) {
      positions[entry.key] = Offset(x, 0);
      x += entry.value.size.width + request.spacing;
    }

    final width = x == 0 ? 0.0 : x - request.spacing;
    final bounds = Rect.fromLTWH(
      0,
      0,
      width,
      request.graph.nodes.values
          .map((n) => n.size.height)
          .fold<double>(0, (maxH, h) => h > maxH ? h : maxH),
    );

    return LayoutResult(positions: positions, bounds: bounds);
  }
}

void main() {
  group('Layout core types', () {
    test('LayoutRequest holds mixed sizes and relationships', () {
      final graph = OrgChartLayoutGraph(
        nodes: {
          'a': const LayoutNode(id: 'a', size: Size(10, 20)),
          'b': const LayoutNode(id: 'b', size: Size(30, 40)),
        },
        parentById: {'a': null, 'b': 'a'},
      );

      final request = LayoutRequest(
        graph: graph,
        orientation: LayoutOrientation.leftToRight,
        spacing: 12,
        runSpacing: 34,
        subtreeId: null,
        allowOverlaps: true,
        enableIncremental: true,
        previousPositions: const {'a': Offset(1, 2)},
      );

      expect(request.graph.parentOf('b'), equals('a'));
      expect(request.graph.nodes['b']!.size, equals(const Size(30, 40)));
      expect(request.orientation, equals(LayoutOrientation.leftToRight));
      expect(request.spacing, equals(12));
      expect(request.runSpacing, equals(34));
      expect(request.subtreeId, isNull);
      expect(request.allowOverlaps, isTrue);
      expect(request.enableIncremental, isTrue);
      expect(request.previousPositions!['a'], equals(const Offset(1, 2)));
    });

    test('LayoutRequest.copyWith supports subtree-only layout inputs', () {
      final graph = OrgChartLayoutGraph(nodes: const {}, parentById: const {});
      final request = LayoutRequest(graph: graph);

      final subtreeRequest = request.copyWith(subtreeId: 'root');

      expect(subtreeRequest.subtreeId, equals('root'));
      expect(subtreeRequest.graph, same(graph));
    });

    test('LayoutResult exposes bounds and contentSize', () {
      final result = LayoutResult(
        positions: const {'a': Offset.zero},
        bounds: const Rect.fromLTWH(5, 7, 11, 13),
      );

      expect(result.bounds.left, equals(5));
      expect(result.contentSize, equals(const Size(11, 13)));
    });

    test('GraphLayoutEngine can be unit-tested without widgets', () {
      final engine = _OrgChartRowEngine();
      final graph = OrgChartLayoutGraph(
        nodes: {
          'a': const LayoutNode(id: 'a', size: Size(10, 10)),
          'b': const LayoutNode(id: 'b', size: Size(20, 10)),
        },
        parentById: const {'a': null, 'b': 'a'},
      );

      final result = engine.layout(LayoutRequest(graph: graph, spacing: 5));

      expect(result.positions['a'], equals(const Offset(0, 0)));
      expect(result.positions['b'], equals(const Offset(15, 0)));
      expect(result.bounds.width, equals(35));
    });
  });
}
