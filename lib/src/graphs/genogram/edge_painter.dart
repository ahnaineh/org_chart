import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:org_chart/src/common/edge_painter.dart';
import 'package:org_chart/src/common/node.dart';
import 'package:org_chart/src/controllers/genogram_controller.dart';

/// Edge painter for genogram charts that shows family relationships
class GenogramEdgePainter<E> extends BaseEdgePainter<E> {
  /// The genogram controller
  final GenogramController<E> genogramController;

  /// Paint for marriage/partnership relationships
  final Paint partnershipPaint;

  /// Paint for children connections
  final Paint childrenPaint;

  GenogramEdgePainter({
    required this.genogramController,
    required Paint linePaint,
    double cornerRadius = 10,
    required GraphArrowStyle arrowStyle,
    Paint? partnershipPaint,
    Paint? childrenPaint,
  })  : partnershipPaint = partnershipPaint ?? Paint()
          ..color = Colors.red
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
        childrenPaint = childrenPaint ?? Paint()
          ..color = Colors.blue
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
        super(
          controller: genogramController,
          linePaint: linePaint,
          cornerRadius: cornerRadius,
          arrowStyle: arrowStyle,
        );

  @override
  void drawNodeConnections(Node<E> node, Canvas canvas) {
    // In a complete implementation, we would draw different types of
    // relationship lines between nodes based on genogramController.getRelations()

    // For now, we'll draw simple blood relation connections (parent-child)
    final List<Node<E>> children = genogramController.getSubNodes(node);

    if (!node.hideNodes && children.isNotEmpty) {
      drawParentChildConnections(node, children, canvas);
    }

    // Draw partnership/marriage connections
    drawPartnershipConnections(canvas);
  }

  /// Draw connections between parent and children
  void drawParentChildConnections(
      Node<E> parent, List<Node<E>> children, Canvas canvas) {
    if (children.isEmpty) return;

    final parentCenter = Offset(
        parent.position.dx + genogramController.boxSize.width / 2,
        parent.position.dy + genogramController.boxSize.height / 2);

    // Draw vertical line down from parent
    final verticalLineBottom = Offset(
        parentCenter.dx, parentCenter.dy + genogramController.runSpacing / 2);

    canvas.drawLine(parentCenter, verticalLineBottom, childrenPaint);

    // If there are multiple children, draw horizontal line connecting them
    if (children.length > 1) {
      final leftmostChild =
          children.reduce((a, b) => a.position.dx < b.position.dx ? a : b);
      final rightmostChild =
          children.reduce((a, b) => a.position.dx > b.position.dx ? a : b);

      final horizontalLineStart = Offset(
          leftmostChild.position.dx + genogramController.boxSize.width / 2,
          verticalLineBottom.dy);

      final horizontalLineEnd = Offset(
          rightmostChild.position.dx + genogramController.boxSize.width / 2,
          verticalLineBottom.dy);

      canvas.drawLine(horizontalLineStart, horizontalLineEnd, childrenPaint);
    }

    // Draw vertical lines up to each child
    for (final child in children) {
      final childTopCenter = Offset(
          child.position.dx + genogramController.boxSize.width / 2,
          child.position.dy);

      canvas.drawLine(Offset(childTopCenter.dx, verticalLineBottom.dy),
          childTopCenter, childrenPaint);

      // Recursively draw connections to grandchildren
      final grandchildren = genogramController.getSubNodes(child);
      if (!child.hideNodes && grandchildren.isNotEmpty) {
        drawParentChildConnections(child, grandchildren, canvas);
      }
    }
  }

  /// Draw connections between partners (marriages, etc.)
  void drawPartnershipConnections(Canvas canvas) {
    final partnerRelations = genogramController.getPartnerRelations();

    for (final relation in partnerRelations) {
      final person1Center = Offset(
          relation.person1.position.dx + genogramController.boxSize.width / 2,
          relation.person1.position.dy + genogramController.boxSize.height / 2);

      final person2Center = Offset(
          relation.person2.position.dx + genogramController.boxSize.width / 2,
          relation.person2.position.dy + genogramController.boxSize.height / 2);

      // Different line styles for different relationship types
      switch (relation.type) {
        case GenogramRelationType.marriage:
          // Solid line for marriage
          canvas.drawLine(person1Center, person2Center, partnershipPaint);
          break;

        case GenogramRelationType.divorce:
          // Double strikethrough line for divorce
          canvas.drawLine(person1Center, person2Center, partnershipPaint);

          // Calculate perpendicular short lines to indicate divorce
          final dx = person2Center.dx - person1Center.dx;
          final dy = person2Center.dy - person1Center.dy;
          final length = math.sqrt(dx * dx + dy * dy);

          if (length > 0) {
            final unitPerpX = -dy / length * 10;
            final unitPerpY = dx / length * 10;

            final midPoint = Offset((person1Center.dx + person2Center.dx) / 2,
                (person1Center.dy + person2Center.dy) / 2);

            // Draw two diagonal lines through the partnership line
            canvas.drawLine(
                Offset(midPoint.dx - unitPerpX, midPoint.dy - unitPerpY),
                Offset(midPoint.dx + unitPerpX, midPoint.dy + unitPerpY),
                partnershipPaint);

            canvas.drawLine(
                Offset(midPoint.dx - unitPerpX - 10, midPoint.dy - unitPerpY),
                Offset(midPoint.dx + unitPerpX - 10, midPoint.dy + unitPerpY),
                partnershipPaint);
          }
          break;

        case GenogramRelationType.separation:
          // Dashed line for separation
          drawDashedLine(
              p1: person1Center,
              p2: person2Center,
              pattern: [5, 5],
              paint: partnershipPaint,
              canvas: canvas);
          break;

        case GenogramRelationType.engagement:
          // Dotted line for engagement
          drawDashedLine(
              p1: person1Center,
              p2: person2Center,
              pattern: [2, 3],
              paint: partnershipPaint,
              canvas: canvas);
          break;

        case GenogramRelationType.cohabitation:
          // Dash-dot line for cohabitation
          drawDashedLine(
              p1: person1Center,
              p2: person2Center,
              pattern: [10, 5, 2, 5],
              paint: partnershipPaint,
              canvas: canvas);
          break;

        default:
          break;
      }
    }
  }
}
