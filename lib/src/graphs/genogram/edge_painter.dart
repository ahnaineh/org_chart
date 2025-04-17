import 'package:flutter/material.dart';
import 'package:org_chart/org_chart.dart';
import 'dart:math' as math;

import 'package:org_chart/src/common/edge_painter.dart';
import 'package:org_chart/src/common/node.dart';
import 'package:org_chart/src/controllers/genogram_controller.dart';

class GenogramEdgePainter<E> extends BaseEdgePainter<E> {
  @override
  final GenogramController<E> controller;

  GenogramEdgePainter({
    required this.controller,
    required super.linePaint,
    super.cornerRadius,
    required super.arrowStyle,
  }) : super(
          controller: controller,
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

  // Compute key points on a node based on orientation
  Offset getCenter(Node<E> node) =>
      node.position +
      Offset(controller.boxSize.width / 2, controller.boxSize.height / 2);

  // Get the connection point for parent-child relationship based on orientation
  Offset getParentConnPoint(Node<E> node) {
    if (controller.orientation == GenogramOrientation.topToBottom) {
      // For topToBottom, connect from bottom center of parent
      return node.position +
          Offset(controller.boxSize.width / 2, controller.boxSize.height);
    } else {
      // For leftToRight, connect from right center of parent
      return node.position +
          Offset(controller.boxSize.width, controller.boxSize.height / 2);
    }
  }

  // Get the connection point for child based on orientation
  Offset getChildConnPoint(Node<E> node) {
    if (controller.orientation == GenogramOrientation.topToBottom) {
      // For topToBottom, connect to top center of child
      return node.position + Offset(controller.boxSize.width / 2, 0);
    } else {
      // For leftToRight, connect to left center of child
      return node.position + Offset(0, controller.boxSize.height / 2);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Map<String, Color> marriageColors = {};
    final Map<String, Offset> marriagePoints =
        {}; // Store middle points of marriages

    // Retrieve all nodes.
    final List<Node<E>> allNodes = controller.nodes;

    // STEP 1: Collect all marriages first
    final List<Map<String, dynamic>> marriageConnections = [];
    final List<Map<String, dynamic>> childConnections = [];

    // First pass: collect all marriages
    for (final Node<E> person in allNodes) {
      final String personId = controller.idProvider(person.data);
      final List<String>? spouses = controller.spousesProvider(person.data);
      if (spouses == null || spouses.isEmpty) continue;

      // Only process if this person is male, to avoid double-counting marriages
      if (!controller.isMale(person.data)) continue;

      final Offset personCenter = getCenter(person);

      for (int i = 0; i < spouses.length; i++) {
        final String spouseId = spouses[i];

        // Find spouse node
        Node<E>? spouse;
        try {
          spouse = allNodes.firstWhere(
            (node) => controller.idProvider(node.data) == spouseId,
          );
        } catch (_) {
          // Spouse not found in the displayed nodes
          continue;
        }

        final String marriageKey = '$personId|$spouseId';
        final Color marriageColor =
            getMarriageColor(marriageKey, marriageColors, availableColors);
        final Offset spouseCenter = getCenter(spouse);

        // Record the marriage
        marriageConnections.add({
          'husband': person,
          'wife': spouse,
          'husbandCenter': personCenter,
          'wifeCenter': spouseCenter,
          'marriageKey': marriageKey,
          'marriageColor': marriageColor,
          'spouseIndex': i,
          'totalSpouses': spouses.length,
        });
      }
    }

    // STEP 2: Draw all marriage lines and store their midpoints
    // Sort by spouseIndex so earlier marriages are drawn first
    marriageConnections
        .sort((a, b) => a['spouseIndex'].compareTo(b['spouseIndex']));

    for (final connection in marriageConnections) {
      final Paint marriagePaint = Paint()
        ..color = connection['marriageColor']
        ..strokeWidth = linePaint.strokeWidth
        ..style = linePaint.style
        ..strokeCap = linePaint.strokeCap;

      final Offset husbandCenter = connection['husbandCenter'];
      final Offset wifeCenter = connection['wifeCenter'];
      final int spouseIndex = connection['spouseIndex'];
      final int totalSpouses = connection['totalSpouses'];

      // Add a small offset for multiple marriages to prevent overlap
      final double offset = 2.0;
      Offset adjustedHusbandCenter, adjustedWifeCenter;

      if (controller.orientation == GenogramOrientation.topToBottom) {
        // For topToBottom, offset in Y direction
        adjustedHusbandCenter = husbandCenter + Offset(0, spouseIndex * offset);
        adjustedWifeCenter = wifeCenter + Offset(0, spouseIndex * offset);
      } else {
        // For leftToRight, offset in X direction
        adjustedHusbandCenter = husbandCenter + Offset(spouseIndex * offset, 0);
        adjustedWifeCenter = wifeCenter + Offset(spouseIndex * offset, 0);
      }

      // Draw the marriage line
      canvas.drawLine(adjustedHusbandCenter, adjustedWifeCenter, marriagePaint);

      // Store the connection point of this marriage for child connections
      final String marriageKey = connection['marriageKey'];

      // Calculate connection point position based on spouse index
      // First wife (index 0): use midpoint (ratio 0.5)
      // Additional wives: move closer to wife position (ratio > 0.5)
      double connectionRatio = 0.5;
      if (spouseIndex > 0 && totalSpouses > 1) {
        connectionRatio = 0.5 + 0.25;
      }

      final Offset marriagePoint = Offset(
          adjustedHusbandCenter.dx +
              (adjustedWifeCenter.dx - adjustedHusbandCenter.dx) *
                  connectionRatio,
          adjustedHusbandCenter.dy +
              (adjustedWifeCenter.dy - adjustedHusbandCenter.dy) *
                  connectionRatio);

      marriagePoints[marriageKey] = marriagePoint;
    }

    // STEP 3: Process children and connect to appropriate parents or marriage points
    for (final Node<E> child in allNodes) {
      final String? fatherId = controller.fatherProvider(child.data);
      final String? motherId = controller.motherProvider(child.data);
      if (fatherId == null && motherId == null) continue;

      final Offset childConnPoint = getChildConnPoint(child);
      final bool isFemale = controller.isFemale(child.data);
      final List<Node<E>> childSpouses = controller.getSpouseList(child.data);
      final bool isMarriedFemale = isFemale && childSpouses.isNotEmpty;

      // Try to find both parents
      Node<E>? father;
      Node<E>? mother;

      if (fatherId != null) {
        try {
          father = allNodes.firstWhere(
            (node) => controller.idProvider(node.data) == fatherId,
          );
        } catch (_) {
          // Father not found
        }
      }

      if (motherId != null) {
        try {
          mother = allNodes.firstWhere(
            (node) => controller.idProvider(node.data) == motherId,
          );
        } catch (_) {
          // Mother not found
        }
      }

      // If both parents exist and they are married
      if (father != null && mother != null) {
        final String marriageKey = '$fatherId|$motherId';

        // If this marriage has a stored point (it was found in the first pass)
        if (marriagePoints.containsKey(marriageKey)) {
          // Use the marriage midpoint for the connection
          final Offset connectionStart = marriagePoints[marriageKey]!;
          final Paint connectionPaint = Paint()
            ..color = marriageColors[marriageKey] ?? linePaint.color
            ..strokeWidth = linePaint.strokeWidth
            ..style = linePaint.style
            ..strokeCap = linePaint.strokeCap;

          if (isMarriedFemale) {
            drawTwoSegmentArrow(
                canvas, connectionStart, childConnPoint, connectionPaint);
          } else {
            drawSegmentedArrow(
                canvas, connectionStart, childConnPoint, connectionPaint);
          }
        } else {
          // This is a parent pair that didn't have a marriage in first pass
          // Draw single parent connections instead
          childConnections.add({
            'parent': father,
            'childConnPoint': childConnPoint,
            'isMarriedFemale': isMarriedFemale,
          });
          childConnections.add({
            'parent': mother,
            'childConnPoint': childConnPoint,
            'isMarriedFemale': isMarriedFemale,
          });
        }
      } else {
        // At least one parent is missing, draw single parent connections
        if (father != null) {
          childConnections.add({
            'parent': father,
            'childConnPoint': childConnPoint,
            'isMarriedFemale': isMarriedFemale,
          });
        }
        if (mother != null) {
          childConnections.add({
            'parent': mother,
            'childConnPoint': childConnPoint,
            'isMarriedFemale': isMarriedFemale,
          });
        }
      }
    }

    // Draw all single parent connections
    for (final connection in childConnections) {
      final bool isMarriedFemale = connection['isMarriedFemale'] ?? false;
      final Node<E> parent = connection['parent'];
      final Offset parentConnPoint = getParentConnPoint(parent);

      if (isMarriedFemale) {
        drawTwoSegmentArrow(
            canvas, parentConnPoint, connection['childConnPoint'], linePaint);
      } else {
        drawStraightArrow(
            canvas, parentConnPoint, connection['childConnPoint'], linePaint);
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
    Offset childConnPoint,
    Paint paint,
  ) {
    if (controller.orientation == GenogramOrientation.topToBottom) {
      // For topToBottom, use vertical then horizontal segments
      final double midY = (arrowStart.dy + childConnPoint.dy) / 2;
      final Offset p1 = arrowStart;
      final Offset p2 = Offset(arrowStart.dx, midY);
      final Offset p3 = Offset(childConnPoint.dx, midY);
      final Offset p4 = childConnPoint;

      canvas.drawLine(p1, p2, paint);
      canvas.drawLine(p2, p3, paint);
      canvas.drawLine(p3, p4, paint);

      // Draw arrow head
      const double arrowHeadLength = 10.0;
      const double arrowHeadAngle = math.pi / 6;
      final double angle = math.atan2(p4.dy - p3.dy, p4.dx - p3.dx);
      drawArrowHead(canvas, p4, angle, arrowHeadLength, arrowHeadAngle, paint);
    } else {
      // For leftToRight, use horizontal then vertical segments
      final double midX = (arrowStart.dx + childConnPoint.dx) / 2;
      final Offset p1 = arrowStart;
      final Offset p2 = Offset(midX, arrowStart.dy);
      final Offset p3 = Offset(midX, childConnPoint.dy);
      final Offset p4 = childConnPoint;

      canvas.drawLine(p1, p2, paint);
      canvas.drawLine(p2, p3, paint);
      canvas.drawLine(p3, p4, paint);

      // Draw arrow head
      const double arrowHeadLength = 10.0;
      const double arrowHeadAngle = math.pi / 6;
      final double angle = math.atan2(p4.dy - p3.dy, p4.dx - p3.dx);
      drawArrowHead(canvas, p4, angle, arrowHeadLength, arrowHeadAngle, paint);
    }
  }

  void drawTwoSegmentArrow(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
  ) {
    Offset midPoint;

    if (controller.orientation == GenogramOrientation.topToBottom) {
      // For topToBottom, middle point is vertically aligned with start
      midPoint = Offset(start.dx, (start.dy + end.dy) / 2);
    } else {
      // For leftToRight, middle point is horizontally aligned with start
      midPoint = Offset((start.dx + end.dx) / 2, start.dy);
    }

    canvas.drawLine(start, midPoint, paint);
    canvas.drawLine(midPoint, end, paint);

    // Draw arrow head
    const double arrowHeadLength = 10.0;
    const double arrowHeadAngle = math.pi / 6;
    final double angle = math.atan2(end.dy - midPoint.dy, end.dx - midPoint.dx);
    drawArrowHead(canvas, end, angle, arrowHeadLength, arrowHeadAngle, paint);
  }

  // Helper method to draw arrow heads
  void drawArrowHead(Canvas canvas, Offset tip, double angle, double headLength,
      double headAngle, Paint paint) {
    final Offset arrowPoint1 = tip -
        Offset(
          headLength * math.cos(angle - headAngle),
          headLength * math.sin(angle - headAngle),
        );
    final Offset arrowPoint2 = tip -
        Offset(
          headLength * math.cos(angle + headAngle),
          headLength * math.sin(angle + headAngle),
        );
    final Path arrowPath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(arrowPoint1.dx, arrowPoint1.dy)
      ..moveTo(tip.dx, tip.dy)
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
