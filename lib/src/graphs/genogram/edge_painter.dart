import 'package:flutter/material.dart';
import 'package:org_chart/org_chart.dart';
import 'dart:math' as math;

import 'package:org_chart/src/common/edge_painter.dart';
import 'package:org_chart/src/common/node.dart';
import 'package:org_chart/src/controllers/genogram_controller.dart';
// import 'package:org_chart/src/controllers/org_chart_controller.dart';
class GenogramEdgePainter<E> extends BaseEdgePainter<E> {
  final GenogramController<E> controller;

  GenogramEdgePainter({
    required this.controller,
    required Paint linePaint,
    double cornerRadius = 10,
    required GraphArrowStyle arrowStyle,
  }) : super(
          controller: controller,
          linePaint: linePaint,
          cornerRadius: cornerRadius,
          arrowStyle: arrowStyle,
        );

  @override
  void paint(Canvas canvas, Size size) {
    // Retrieve the box size from the controller.
    final Size boxSize = controller.boxSize;

    // Track drawn marriage connections (keyed by "fatherId|motherId") to avoid duplicates.
    final Set<String> drawnMarriageConnections = {};

    // Helper to draw an arrow with arrowheads.
    void drawArrow(Canvas canvas, Offset start, Offset end) {
      // Draw the main line.
      canvas.drawLine(start, end, linePaint);

      // Calculate arrowhead properties.
      const double arrowHeadLength = 10.0;
      const double arrowHeadAngle = math.pi / 6; // 30 degrees.

      final double angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
      final Offset arrowPoint1 = end - Offset(
        arrowHeadLength * math.cos(angle - arrowHeadAngle),
        arrowHeadLength * math.sin(angle - arrowHeadAngle),
      );
      final Offset arrowPoint2 = end - Offset(
        arrowHeadLength * math.cos(angle + arrowHeadAngle),
        arrowHeadLength * math.sin(angle + arrowHeadAngle),
      );

      final Path arrowPath = Path()
        ..moveTo(end.dx, end.dy)
        ..lineTo(arrowPoint1.dx, arrowPoint1.dy)
        ..moveTo(end.dx, end.dy)
        ..lineTo(arrowPoint2.dx, arrowPoint2.dy);
      canvas.drawPath(arrowPath, linePaint);
    }

    // Helpers to compute key points on a node.
    Offset getBottomCenter(Node<E> node) =>
        node.position + Offset(boxSize.width / 2, boxSize.height);
    Offset getTopCenter(Node<E> node) =>
        node.position + Offset(boxSize.width / 2, 0);

    // Assume all nodes are available via the controller.
    final List<Node<E>> allNodes = controller.nodes;

    // Iterate through each node that may be a child (has parent info).
    for (final Node<E> child in allNodes) {
      final String? fatherId = controller.fatherProvider(child.data);
      final String? motherId = controller.motherProvider(child.data);

      // Skip if the child has no parent data.
      if (fatherId == null && motherId == null) continue;

      Node<E>? father;
      Node<E>? mother;

      // Find the father and mother nodes.
      if (fatherId != null) {
        father = allNodes.firstWhere(
          (node) => controller.idProvider(node.data) == fatherId,
          // orElse: () => null,
        );
      }
      if (motherId != null) {
        mother = allNodes.firstWhere(
          (node) => controller.idProvider(node.data) == motherId,
          // orElse: () => null,
        );
      }

      final Offset childTop = getTopCenter(child);

      // If both parents exist, check if they are married.
      if (father != null && mother != null) {
        final String fatherNodeId = controller.idProvider(father.data);
        final String motherNodeId = controller.idProvider(mother.data);

        final List<String>? fatherSpouses = controller.spousesProvider(father.data);
        final List<String>? motherSpouses = controller.spousesProvider(mother.data);

        bool areMarried = false;
        if (fatherSpouses != null && fatherSpouses.contains(motherNodeId)) {
          areMarried = true;
        } else if (motherSpouses != null && motherSpouses.contains(fatherNodeId)) {
          areMarried = true;
        }

        if (areMarried) {
          // Create a unique key for this marriage connection.
          final String marriageKey = '$fatherNodeId|$motherNodeId';

          final Offset fatherBottom = getBottomCenter(father);
          final Offset motherBottom = getBottomCenter(mother);

          // Draw the marriage connection line once.
          if (!drawnMarriageConnections.contains(marriageKey)) {
            canvas.drawLine(fatherBottom, motherBottom, linePaint);
            drawnMarriageConnections.add(marriageKey);
          }

          // Compute the midpoint of the marriage connection.
          final Offset marriageMidpoint = Offset(
            (fatherBottom.dx + motherBottom.dx) / 2,
            fatherBottom.dy,
          );
          // Draw a single arrow from the marriage connection midpoint to the child.
          drawArrow(canvas, marriageMidpoint, childTop);
        } else {
          // If not married, draw separate arrows from each parent's bottom center.
          drawArrow(canvas, getBottomCenter(father), childTop);
          drawArrow(canvas, getBottomCenter(mother), childTop);
        }
      } else {
        // If only one parent is found, draw arrow from that parent's bottom center.
        if (father != null) {
          drawArrow(canvas, getBottomCenter(father), childTop);
        }
        if (mother != null) {
          drawArrow(canvas, getBottomCenter(mother), childTop);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant GenogramEdgePainter<E> oldDelegate) {
    // Repaint if the controller or painting styles have changed.
    return controller != oldDelegate.controller ||
        linePaint != oldDelegate.linePaint ||
        arrowStyle != oldDelegate.arrowStyle;
  }
}
