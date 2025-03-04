import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:org_chart/src/common/node.dart';
import 'package:org_chart/src/controllers/base_controller.dart';

/// Base abstract class for arrow/line styles in graphs
abstract class GraphArrowStyle {
  const GraphArrowStyle();
}

/// A graph arrow style that renders a solid arrow
class SolidGraphArrow extends GraphArrowStyle {
  const SolidGraphArrow();
}

/// A graph arrow style that renders a dashed arrow using a customizable dash pattern
class DashedGraphArrow extends GraphArrowStyle {
  /// The dash pattern is defined by the `pattern` parameter, which specifies
  /// alternating lengths of dashes and gaps.
  ///
  /// **Pattern Structure:**
  /// - Even indices (`0, 2, 4, ...`) represent the length of dashes.
  /// - Odd indices (`1, 3, 5, ...`) represent the length of gaps.
  /// - The pattern repeats cyclically until the line is fully drawn.
  ///
  /// The `pattern` length is required to be even to maintain a valid
  /// dash-gap sequence.
  final Iterable<double> pattern;
  const DashedGraphArrow({
    this.pattern = const [10, 5],
  });
}

/// Base edge painter class that should be extended by specific graph types
abstract class BaseEdgePainter<E> extends CustomPainter {
  /// The controller that manages graph data
  final BaseGraphController<E> controller;

  /// The paint configuration for drawing lines
  final Paint linePaint;

  /// Corner radius for curved edges
  final double cornerRadius;

  /// Arrow/line style configuration
  final GraphArrowStyle arrowStyle;

  /// Path used to draw the lines
  final Path linePath = Path();

  BaseEdgePainter({
    required this.controller,
    required this.linePaint,
    this.cornerRadius = 10,
    required this.arrowStyle,
  });

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  /// Draw arrows for all root nodes
  @override
  void paint(Canvas canvas, Size size) {
    linePath.reset();
    for (var node in controller.roots) {
      drawNodeConnections(node, canvas);
    }

    canvas.drawPath(linePath, linePaint);
  }

  /// Implement in subclass to draw connections for a specific node
  void drawNodeConnections(Node<E> node, Canvas canvas);

  /// Draw a line between two points with the configured style
  void drawArrow({
    required Offset p1,
    required Offset p2,
    required Canvas canvas,
  }) {
    switch (arrowStyle) {
      case SolidGraphArrow _:
        linePath.moveTo(p1.dx, p1.dy);
        linePath.lineTo(p2.dx, p2.dy);
        break;
      case DashedGraphArrow _:
        drawDashedLine(
          p1: p1,
          p2: p2,
          pattern: (arrowStyle as DashedGraphArrow).pattern,
          paint: linePaint,
          canvas: canvas,
        );
        linePath.moveTo(p2.dx, p2.dy);
        break;
    }
  }

  /// Helper method to draw a dashed line between two points
  void drawDashedLine({
    required Canvas canvas,
    required Offset p1,
    required Offset p2,
    required Iterable<double> pattern,
    required Paint paint,
  }) {
    assert(
        pattern.length.isEven, "Pattern must have an even number of elements");
    final distance = (p2 - p1).distance;
    final normalizedPattern = pattern.map((width) => width / distance).toList();
    final points = <Offset>[];
    double t = 0;
    int i = 0;
    while (t < 1) {
      points.add(Offset.lerp(p1, p2, t)!);
      t += normalizedPattern[i++]; // dashWidth
      points.add(Offset.lerp(p1, p2, t.clamp(0, 1))!);
      t += normalizedPattern[i++]; // dashSpace
      i %= normalizedPattern.length;
    }
    canvas.drawPoints(ui.PointMode.lines, points, paint);
  }
}
