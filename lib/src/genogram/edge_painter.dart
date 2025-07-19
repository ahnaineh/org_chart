import 'package:flutter/material.dart';
import 'package:org_chart/src/base/edge_painter_utils.dart';
import 'package:org_chart/src/genogram/genogram_enums.dart';
import 'package:org_chart/src/common/node.dart';
import 'package:org_chart/src/base/base_controller.dart';
import 'package:org_chart/src/genogram/genogram_controller.dart';
import 'package:org_chart/src/genogram/genogram_edge_config.dart';

/// Connection points on a node
enum ConnectionPoint {
  top,
  right,
  bottom,
  left,
  center,
}

/// Relationship type in a genogram
enum RelationshipType {
  marriage,
  parent,
  child,
}

/// A highly customizable painter for genogram edges
class GenogramEdgePainter<E> extends CustomPainter {
  final GenogramController<E> controller;

  final EdgePainterUtils utils;

  /// Configuration for edge styling
  final GenogramEdgeConfig config;

  /// Function to get marriage status for a relationship (defaults to married)
  final MarriageStatus Function(E person, E spouse)? marriageStatusProvider;
  // Maps to track marriage connections
  final Map<String, Color> _marriageColors = {};
  final Map<String, Offset> _marriagePoints = {};

  GenogramEdgePainter({
    required this.controller,
    required Paint linePaint,
    double cornerRadius = 15,
    required GraphArrowStyle arrowStyle,
    this.config = const GenogramEdgeConfig(),
    this.marriageStatusProvider,
  }) : utils = EdgePainterUtils(
          linePaint: linePaint,
          cornerRadius: cornerRadius,
          arrowStyle: arrowStyle,
        );

  @override
  void paint(Canvas canvas, Size size) {
    // Clear tracking maps for new painting cycle
    _marriageColors.clear();
    _marriagePoints.clear();

    final List<Node<E>> allNodes = controller.nodes;

    // First pass: Draw marriage connections
    _drawMarriageConnections(canvas, allNodes);

    // Second pass: Draw parent-child connections
    _drawParentChildConnections(canvas, allNodes);
  }

  /// Draw marriage connections between spouses
  void _drawMarriageConnections(Canvas canvas, List<Node<E>> nodes) {
    // First collect all marriages to properly index colors
    final marriages = <Map<String, dynamic>>[];

    // Collect marriages
    for (final Node<E> person in nodes) {
      final String personId = controller.idProvider(person.data);
      final List<String>? spouses = controller.spousesProvider(person.data);

      // Skip if no spouses
      if (spouses == null || spouses.isEmpty) continue;

      // Only process marriages from males to avoid duplication
      if (!controller.isMale(person.data)) continue;

      for (int i = 0; i < spouses.length; i++) {
        final String spouseId = spouses[i];

        // Find spouse node
        Node<E>? spouse;
        try {
          spouse = nodes.firstWhere(
            (node) => controller.idProvider(node.data) == spouseId,
          );
        } catch (_) {
          continue; // Spouse not found
        }

        // Add to marriages collection
        marriages.add({
          'husband': person,
          'wife': spouse,
          'spouseIndex': i,
          'marriageKey': '$personId|$spouseId',
        });
      }
    }

    // Sort marriages to ensure consistent color assignment
    marriages.sort((a, b) => a['marriageKey'].compareTo(b['marriageKey']));

    // Assign colors and draw marriages
    for (int i = 0; i < marriages.length; i++) {
      final marriage = marriages[i];
      final Node<E> husband = marriage['husband'];
      final Node<E> wife = marriage['wife'];
      final int spouseIndex = marriage['spouseIndex'];
      final String marriageKey = marriage['marriageKey']; // Assign color
      final Color marriageColor =
          config.marriageColors[i % config.marriageColors.length];
      _marriageColors[marriageKey] = marriageColor;

      // Get connection points
      final Offset husbandConn =
          _getConnectionPoint(husband, ConnectionPoint.right);
      final Offset wifeConn = _getConnectionPoint(wife, ConnectionPoint.left);

      // Apply offset for multiple marriages
      final double offset = -5.0 * spouseIndex;
      final Offset husbandOffset, wifeOffset;

      if (controller.orientation == GraphOrientation.topToBottom) {
        husbandOffset = husbandConn.translate(0, offset);
        wifeOffset = wifeConn.translate(0, offset);
      } else {
        husbandOffset = husbandConn.translate(offset, 0);
        wifeOffset = wifeConn.translate(offset, 0);
      } // Determine marriage status if provider exists
      MarriageStatus status = MarriageStatus.married;
      if (marriageStatusProvider != null) {
        status = marriageStatusProvider!(husband.data, wife.data);
      }

      // Get the appropriate marriage style for this status
      final marriageStyle = config.getMarriageStyle(status);

      // Create custom paint for this marriage
      final Paint marriagePaint = Paint()
        ..color = marriageColor
        ..strokeWidth = marriageStyle.lineStyle.strokeWidth
        ..style = marriageStyle.lineStyle.paintStyle;

      // Draw the marriage line
      canvas.drawLine(husbandOffset, wifeOffset,
          marriagePaint); // Calculate connection point based on spouse index
      // For first spouse (index 0): use midpoint (ratio 0.5)
      // For additional spouses: move closer to wife (ratio > 0.5)
      double connectionRatio = spouseIndex == 0 ? 0.5 : 0.9;

      // Store the weighted point for child connections
      _marriagePoints[marriageKey] = Offset(
          husbandOffset.dx +
              (wifeOffset.dx - husbandOffset.dx) * connectionRatio,
          husbandOffset.dy +
              (wifeOffset.dy - husbandOffset.dy) * connectionRatio);
    }
  }

  /// Draw connections between parents and children
  void _drawParentChildConnections(Canvas canvas, List<Node<E>> nodes) {
    for (final Node<E> child in nodes) {
      // Get parent IDs
      final String? fatherId = controller.fatherProvider(child.data);
      final String? motherId = controller.motherProvider(child.data);

      // Skip if no parent info
      if (fatherId == null && motherId == null) continue;

      // Find parent nodes
      Node<E>? father, mother;

      if (fatherId != null) {
        try {
          father = nodes.firstWhere(
              (node) => controller.idProvider(node.data) == fatherId);
        } catch (_) {
          father = null;
        }
      }

      if (motherId != null) {
        try {
          mother = nodes.firstWhere(
              (node) => controller.idProvider(node.data) == motherId);
        } catch (_) {
          mother = null;
        }
      }

      // Get connection point on child
      final Offset childConn = _getConnectionPoint(
          child, ConnectionPoint.top); // Special case for married female
      final bool isMarriedFemale = controller.isFemale(child.data) &&
          controller.getSpouseList(child.data).isNotEmpty;

      // Different cases of parent-child connections
      if (father != null && mother != null) {
        // Both parents present - try to find their marriage connection
        final String marriageKey =
            '${controller.idProvider(father.data)}|${controller.idProvider(mother.data)}';

        if (_marriagePoints.containsKey(marriageKey)) {
          // Draw from marriage point to child
          final Offset marriagePoint = _marriagePoints[marriageKey]!;
          final Color marriageColor =
              _marriageColors[marriageKey] ?? Colors.grey;

          // Create parent-child paint from the configuration
          final Paint connectionPaint = Paint()
            ..color = marriageColor
            ..strokeWidth = config.childStrokeWidth
            ..style = PaintingStyle.stroke;

          // Use two-segment connection for married females
          final connectionType = isMarriedFemale
              ? ConnectionType.twoSegment
              : ConnectionType.threeSegment;

          utils.drawConnection(canvas, marriagePoint, childConn,
              controller.boxSize, controller.orientation,
              type: connectionType, paint: connectionPaint);
        } else {
          // Fall back to connecting from father
          _drawSingleParentConnection(canvas, father, child, isMarriedFemale);
        }
      } else if (father != null) {
        // Father only
        _drawSingleParentConnection(canvas, father, child, isMarriedFemale);
      } else if (mother != null) {
        // Mother only
        _drawSingleParentConnection(canvas, mother, child, isMarriedFemale);
      }
    }
  }

  /// Draw a connection between a single parent and child
  void _drawSingleParentConnection(
      Canvas canvas, Node<E> parent, Node<E> child, bool isMarriedFemale) {
    final Paint parentPaint = Paint()
      ..color = config.childSingleParentColor
      ..strokeWidth = config.childSingleParentStrokeWidth
      ..style = PaintingStyle.stroke;

    final Offset parentConn =
        _getConnectionPoint(parent, ConnectionPoint.bottom);
    final Offset childConn = _getConnectionPoint(child, ConnectionPoint.top);

    final connectionType =
        isMarriedFemale ? ConnectionType.twoSegment : ConnectionType.direct;

    utils.drawConnection(canvas, parentConn, childConn, controller.boxSize,
        controller.orientation,
        type: connectionType, paint: parentPaint);
  }

  /// Get connection point on a node based on location
  Offset _getConnectionPoint(Node<E> node, ConnectionPoint point) {
    switch (point) {
      case ConnectionPoint.top:
        return node.position + Offset(controller.boxSize.width / 2, 0);
      case ConnectionPoint.right:
        return node.position +
            Offset(controller.boxSize.width, controller.boxSize.height / 2);
      case ConnectionPoint.bottom:
        return node.position +
            Offset(controller.boxSize.width / 2, controller.boxSize.height);
      case ConnectionPoint.left:
        return node.position + Offset(0, controller.boxSize.height / 2);
      case ConnectionPoint.center:
        return node.position +
            Offset(controller.boxSize.width / 2, controller.boxSize.height / 2);
    }
  }

  @override
  bool shouldRepaint(covariant GenogramEdgePainter<E> oldDelegate) => true;
}
