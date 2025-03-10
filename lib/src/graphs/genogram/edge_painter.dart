import 'package:flutter/material.dart';
import 'package:org_chart/org_chart.dart';
import 'dart:math' as math;

import 'package:org_chart/src/common/edge_painter.dart';
import 'package:org_chart/src/common/node.dart';
import 'package:org_chart/src/controllers/genogram_controller.dart';

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

  // Predefined colors to differentiate each marriage connection.
  final List<Color> availableColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
  ];
  // Compute key points on a node.
  Offset getCenter(Node<E> node) =>
      node.position +
      Offset(controller.boxSize.width / 2, controller.boxSize.height / 2);
  Offset getTopCenter(Node<E> node) =>
      node.position + Offset(controller.boxSize.width / 2, 0);

  @override
  void paint(Canvas canvas, Size size) {
    final Map<String, Color> marriageColors = {};

    // Retrieve all nodes.
    final List<Node<E>> allNodes = controller.nodes;

    // Collect marriage connections to draw in a specific order
    final List<Map<String, dynamic>> marriageConnections = [];
    final List<Map<String, dynamic>> singleParentConnections = [];

    // Process each node that may be a child.
    for (final Node<E> child in allNodes) {
      final String? fatherId = controller.fatherProvider(child.data);
      final String? motherId = controller.motherProvider(child.data);
      if (fatherId == null && motherId == null) continue;

      // Check if this child is a woman and is married
      final bool isFemale = controller.genderProvider != null &&
          controller.genderProvider!(child.data) == Gender.female;
      final List<String>? spouses = controller.spousesProvider(child.data);
      final bool isMarried = spouses != null && spouses.isNotEmpty;
      final bool isMarriedFemale = isFemale && isMarried;

      Node<E>? father;
      Node<E>? mother;
      if (fatherId != null) {
        father = allNodes.firstWhere(
          (node) => controller.idProvider(node.data) == fatherId,
        );
      }
      if (motherId != null) {
        mother = allNodes.firstWhere(
          (node) => controller.idProvider(node.data) == motherId,
        );
      }
      final Offset childTop = getTopCenter(child);

      if (father != null && mother != null) {
        final String fatherNodeId = controller.idProvider(father.data);
        final String motherNodeId = controller.idProvider(mother.data);
        final List<String>? fatherSpouses =
            controller.spousesProvider(father.data);
        final List<String>? motherSpouses =
            controller.spousesProvider(mother.data);

        bool areMarried = false;
        if (fatherSpouses != null && fatherSpouses.contains(motherNodeId)) {
          areMarried = true;
        } else if (motherSpouses != null &&
            motherSpouses.contains(fatherNodeId)) {
          areMarried = true;
        }

        if (areMarried) {
          final String marriageKey = '$fatherNodeId|$motherNodeId';
          final Color marriageColor =
              getMarriageColor(marriageKey, marriageColors, availableColors);

          marriageConnections.add({
            'father': father,
            'mother': mother,
            'child': child,
            'fatherCenter': getCenter(father),
            'motherCenter': getCenter(mother),
            'childTop': childTop,
            'marriageKey': marriageKey,
            'marriageColor': marriageColor,
            'spouseIndex':
                fatherSpouses != null ? fatherSpouses.indexOf(motherNodeId) : 0,
            'totalSpouses': fatherSpouses != null ? fatherSpouses.length : 1,
            'isMarriedFemale': isMarriedFemale,
          });
        } else {
          singleParentConnections.add({
            'parent': father,
            'childTop': childTop,
            'isMarriedFemale': isMarriedFemale,
          });
          singleParentConnections.add({
            'parent': mother,
            'childTop': childTop,
            'isMarriedFemale': isMarriedFemale,
          });
        }
      } else {
        if (father != null) {
          singleParentConnections.add({
            'parent': father,
            'childTop': childTop,
            'isMarriedFemale': isMarriedFemale,
          });
        }
        if (mother != null) {
          singleParentConnections.add({
            'parent': mother,
            'childTop': childTop,
            'isMarriedFemale': isMarriedFemale,
          });
        }
      }
    }

    marriageConnections
        .sort((a, b) => b['spouseIndex'].compareTo(a['spouseIndex']));

    for (final connection in marriageConnections) {
      final Paint marriagePaint = Paint()
        ..color = connection['marriageColor']
        ..strokeWidth = linePaint.strokeWidth
        ..style = linePaint.style
        ..strokeCap = linePaint.strokeCap;

      final Offset fatherCenter = connection['fatherCenter'];
      final Offset motherCenter = connection['motherCenter'];
      final Offset childTop = connection['childTop'];
      final bool isMarriedFemale = connection['isMarriedFemale'] ?? false;

      canvas.drawLine(fatherCenter, motherCenter, marriagePaint);

      Offset arrowStart;
      if (connection['totalSpouses'] > 1) {
        final int index = connection['spouseIndex'];
        final double distance = (fatherCenter - motherCenter).distance;
        const double threshold = 100.0;
        if (distance < threshold) {
          const double offsetAmount = 5.0;
          arrowStart = Offset.lerp(fatherCenter, motherCenter, 0.5)! +
              Offset(0, index * offsetAmount);
        } else {
          final double lerpFactor = (connection['totalSpouses'] > 1)
              ? (index / (connection['totalSpouses'] - 1)) * 0.25 + 0.5
              : 0.5;
          arrowStart = Offset.lerp(fatherCenter, motherCenter, lerpFactor)!;
        }
      } else {
        arrowStart = Offset.lerp(fatherCenter, motherCenter, 0.5)!;
      }

      if (isMarriedFemale) {
        drawTwoSegmentArrow(canvas, arrowStart, childTop, marriagePaint);
      } else {
        drawSegmentedArrow(canvas, arrowStart, childTop, marriagePaint);
      }
    }

    for (final connection in singleParentConnections) {
      final bool isMarriedFemale = connection['isMarriedFemale'] ?? false;

      if (isMarriedFemale) {
        drawTwoSegmentArrow(canvas, getCenter(connection['parent']),
            connection['childTop'], linePaint);
      } else {
        drawStraightArrow(canvas, getCenter(connection['parent']),
            connection['childTop'], linePaint);
      }
    }
  }

  Color getMarriageColor(String key, Map<String, Color> marriageColors,
      List<Color> availableColors) {
    if (!marriageColors.containsKey(key)) {
      marriageColors[key] =
          availableColors[marriageColors.length % availableColors.length];
    }
    return marriageColors[key]!;
  }

  void drawStraightArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    canvas.drawLine(start, end, paint);
    const double arrowHeadLength = 10.0;
    const double arrowHeadAngle = math.pi / 6;
    final double angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    final Offset arrowPoint1 = end -
        Offset(
          arrowHeadLength * math.cos(angle - arrowHeadAngle),
          arrowHeadLength * math.sin(angle - arrowHeadAngle),
        );
    final Offset arrowPoint2 = end -
        Offset(
          arrowHeadLength * math.cos(angle + arrowHeadAngle),
          arrowHeadLength * math.sin(angle + arrowHeadAngle),
        );
    final Path arrowPath = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(arrowPoint1.dx, arrowPoint1.dy)
      ..moveTo(end.dx, end.dy)
      ..lineTo(arrowPoint2.dx, arrowPoint2.dy);
    canvas.drawPath(arrowPath, paint);
  }

  void drawSegmentedArrow(
    Canvas canvas,
    Offset arrowStart,
    Offset childTop,
    Paint paint,
  ) {
    final double midY = (arrowStart.dy + childTop.dy) / 2;
    final Offset p1 = arrowStart;
    final Offset p2 = Offset(arrowStart.dx, midY);
    final Offset p3 = Offset(childTop.dx, midY);
    final Offset p4 = childTop;
    canvas.drawLine(p1, p2, paint);
    canvas.drawLine(p2, p3, paint);
    canvas.drawLine(p3, p4, paint);

    const double arrowHeadLength = 10.0;
    const double arrowHeadAngle = math.pi / 6;
    final double angle = math.atan2(p4.dy - p3.dy, p4.dx - p3.dx);
    final Offset arrowPoint1 = p4 -
        Offset(
          arrowHeadLength * math.cos(angle - arrowHeadAngle),
          arrowHeadLength * math.sin(angle - arrowHeadAngle),
        );
    final Offset arrowPoint2 = p4 -
        Offset(
          arrowHeadLength * math.cos(angle + arrowHeadAngle),
          arrowHeadLength * math.sin(angle + arrowHeadAngle),
        );
    final Path arrowPath = Path()
      ..moveTo(p4.dx, p4.dy)
      ..lineTo(arrowPoint1.dx, arrowPoint1.dy)
      ..moveTo(p4.dx, p4.dy)
      ..lineTo(arrowPoint2.dx, arrowPoint2.dy);
    canvas.drawPath(arrowPath, paint);
  }

  void drawTwoSegmentArrow(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
  ) {
    final Offset midPoint = Offset(start.dx, (start.dy + end.dy) / 2);

    canvas.drawLine(start, midPoint, paint);
    canvas.drawLine(midPoint, end, paint);

    const double arrowHeadLength = 10.0;
    const double arrowHeadAngle = math.pi / 6;
    final double angle = math.atan2(end.dy - midPoint.dy, end.dx - midPoint.dx);
    final Offset arrowPoint1 = end -
        Offset(
          arrowHeadLength * math.cos(angle - arrowHeadAngle),
          arrowHeadLength * math.sin(angle - arrowHeadAngle),
        );
    final Offset arrowPoint2 = end -
        Offset(
          arrowHeadLength * math.cos(angle + arrowHeadAngle),
          arrowHeadLength * math.sin(angle + arrowHeadAngle),
        );
    final Path arrowPath = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(arrowPoint1.dx, arrowPoint1.dy)
      ..moveTo(end.dx, end.dy)
      ..lineTo(arrowPoint2.dx, arrowPoint2.dy);
    canvas.drawPath(arrowPath, paint);
  }

  @override
  bool shouldRepaint(covariant GenogramEdgePainter<E> oldDelegate) {
    return controller != oldDelegate.controller ||
        linePaint != oldDelegate.linePaint ||
        arrowStyle != oldDelegate.arrowStyle;
  }
}
