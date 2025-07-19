import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:org_chart/org_chart.dart';

class WidgetTestItem {
  final String id;
  final String name;
  final String? managerId;

  WidgetTestItem({required this.id, required this.name, this.managerId});
}

void main() {
  group('OrgChart Widget Tests', () {
    late OrgChartController<WidgetTestItem> controller;
    late List<WidgetTestItem> items;

    setUp(() {
      items = [
        WidgetTestItem(id: '1', name: 'CEO'),
        WidgetTestItem(id: '2', name: 'Manager', managerId: '1'),
        WidgetTestItem(id: '3', name: 'Employee', managerId: '2'),
      ];

      controller = OrgChartController<WidgetTestItem>(
        items: items,
        idProvider: (item) => item.id,
        toProvider: (item) => item.managerId,
      );
    });

    testWidgets('OrgChart renders all nodes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrgChart<WidgetTestItem>(
              controller: controller,
              builder: (details) => Container(
                width: 100,
                height: 50,
                color: Colors.blue,
                child: Center(
                  child: Text(details.item.name),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // All nodes should be rendered
      expect(find.text('CEO'), findsOneWidget);
      expect(find.text('Manager'), findsOneWidget);
      expect(find.text('Employee'), findsOneWidget);
    });

    testWidgets('Node builder receives correct details', (WidgetTester tester) async {
      NodeBuilderDetails<WidgetTestItem>? capturedDetails;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrgChart<WidgetTestItem>(
              controller: controller,
              builder: (details) {
                if (details.item.id == '2') {
                  capturedDetails = details;
                }
                return Container(
                  width: 100,
                  height: 50,
                  child: Text(details.item.name),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(capturedDetails, isNotNull);
      expect(capturedDetails!.item.name, equals('Manager'));
      expect(capturedDetails!.level, equals(2));
      expect(capturedDetails!.nodesHidden, isFalse);
      expect(capturedDetails!.isBeingDragged, isFalse);
      expect(capturedDetails!.isOverlapped, isFalse);
    });

    // Note: Drag and drop functionality requires proper node positioning
    // and overlap detection which is complex to test in widget tests.
    // This functionality is tested manually in the examples.

    testWidgets('Custom styling options', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrgChart<WidgetTestItem>(
              controller: controller,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              linePaint: Paint()
                ..color = Colors.red
                ..strokeWidth = 3,
              arrowStyle: const DashedGraphArrow(),
              cornerRadius: 20,
              builder: (details) => Container(
                width: 100,
                height: 50,
                color: Colors.green,
                child: Text(details.item.name),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check that custom widgets are rendered
      final containers = find.byType(Container);
      expect(containers, findsWidgets);
    });

    testWidgets('Orientation changes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrgChart<WidgetTestItem>(
              controller: controller,
              builder: (details) => Container(
                width: 100,
                height: 50,
                color: Colors.blue,
                child: Text(details.item.name),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Change orientation
      controller.orientation = GraphOrientation.leftToRight;
      await tester.pumpAndSettle();

      expect(controller.orientation, equals(GraphOrientation.leftToRight));
    });

    testWidgets('Empty chart renders without error', (WidgetTester tester) async {
      final emptyController = OrgChartController<WidgetTestItem>(
        items: [],
        idProvider: (item) => item.id,
        toProvider: (item) => item.managerId,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrgChart<WidgetTestItem>(
              controller: emptyController,
              builder: (details) => Container(
                width: 100,
                height: 50,
                color: Colors.blue,
                child: Text(details.item.name),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render without throwing
      expect(find.byType(OrgChart<WidgetTestItem>), findsOneWidget);
    });

    testWidgets('Interactive viewer integration', (WidgetTester tester) async {
      final viewerController = CustomInteractiveViewerController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrgChart<WidgetTestItem>(
              controller: controller,
              viewerController: viewerController,
              enableZoom: true,
              minScale: 0.5,
              maxScale: 2.0,
              builder: (details) => Container(
                width: 100,
                height: 50,
                color: Colors.blue,
                child: Text(details.item.name),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Pinch to zoom
      final center = tester.getCenter(find.byType(OrgChart<WidgetTestItem>));
      final pointer1 = await tester.startGesture(center + const Offset(-50, 0));
      final pointer2 = await tester.startGesture(center + const Offset(50, 0));

      await pointer1.moveBy(const Offset(-50, 0));
      await pointer2.moveBy(const Offset(50, 0));
      await tester.pump();

      await pointer1.up();
      await pointer2.up();
      await tester.pumpAndSettle();

      // Chart should still be rendered
      expect(find.byType(OrgChart<WidgetTestItem>), findsOneWidget);
    });
  });
}