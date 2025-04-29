import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Represents the style of a marriage line in a genogram
class MarriageLineStyle {
  /// The color of the marriage line
  final Color color;

  /// The stroke width of the marriage line
  final double strokeWidth;

  /// The style of the marriage line (solid, dashed, etc.)
  final PaintingStyle paintStyle;

  /// Optional dash pattern if using dashed lines
  final List<double>? dashPattern;

  /// Creates a new marriage line style
  const MarriageLineStyle({
    this.color = Colors.black,
    this.strokeWidth = 1.0,
    this.paintStyle = PaintingStyle.stroke,
    this.dashPattern,
  });

  /// Creates a marriage line style with a solid line
  factory MarriageLineStyle.solid({
    Color color = Colors.black,
    double strokeWidth = 1.0,
  }) {
    return MarriageLineStyle(
      color: color,
      strokeWidth: strokeWidth,
      paintStyle: PaintingStyle.stroke,
    );
  }

  /// Creates a marriage line style with a dashed line
  factory MarriageLineStyle.dashed({
    Color color = Colors.black,
    double strokeWidth = 1.0,
    List<double> dashPattern = const [5, 5],
  }) {
    return MarriageLineStyle(
      color: color,
      strokeWidth: strokeWidth,
      paintStyle: PaintingStyle.stroke,
      dashPattern: dashPattern,
    );
  }

  /// Creates a copy of this style with the given properties replaced
  MarriageLineStyle copyWith({
    Color? color,
    double? strokeWidth,
    PaintingStyle? paintStyle,
    List<double>? dashPattern,
  }) {
    return MarriageLineStyle(
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      paintStyle: paintStyle ?? this.paintStyle,
      dashPattern: dashPattern ?? this.dashPattern,
    );
  }
}

/// Represents the style of a specific marriage relationship
class MarriageStyle {
  /// The style of the marriage line
  final MarriageLineStyle lineStyle;

  /// Optional decorator to be drawn at the center of the marriage line
  final MarriageDecorator? decorator;

  /// Creates a new marriage style
  const MarriageStyle({
    required this.lineStyle,
    this.decorator,
  });

  /// Creates a marriage style for a standard marriage
  factory MarriageStyle.standard({
    Color color = Colors.black,
    double strokeWidth = 1.0,
  }) {
    return MarriageStyle(
      lineStyle: MarriageLineStyle.solid(
        color: color,
        strokeWidth: strokeWidth,
      ),
    );
  }

  /// Creates a marriage style for a divorced marriage
  factory MarriageStyle.divorced({
    Color color = Colors.black,
    double strokeWidth = 1.0,
  }) {
    return MarriageStyle(
      lineStyle: MarriageLineStyle.solid(
        color: color,
        strokeWidth: strokeWidth,
      ),
      decorator: DivorceDecorator(),
    );
  }

  /// Creates a marriage style for a separated marriage
  factory MarriageStyle.separated({
    Color color = Colors.black,
    double strokeWidth = 1.0,
  }) {
    return MarriageStyle(
      lineStyle: MarriageLineStyle.dashed(
        color: color,
        strokeWidth: strokeWidth,
      ),
    );
  }

  /// Creates a copy of this style with the given properties replaced
  MarriageStyle copyWith({
    MarriageLineStyle? lineStyle,
    MarriageDecorator? decorator,
  }) {
    return MarriageStyle(
      lineStyle: lineStyle ?? this.lineStyle,
      decorator: decorator ?? this.decorator,
    );
  }
}

/// Base abstract class for decorators that can be applied to marriage lines
abstract class MarriageDecorator {
  const MarriageDecorator();

  /// Draws the decorator at the specified position
  void paint(Canvas canvas, Offset start, Offset end,
      {double strokeWidth = 1.0});
}

/// A decorator that draws a diagonal line through a marriage line to indicate divorce
class DivorceDecorator extends MarriageDecorator {
  /// The color of the divorce line
  final Color color;

  /// The length of the perpendicular line for divorce indicator
  final double slashLength;

  const DivorceDecorator({
    this.color = Colors.red,
    this.slashLength = 10.0,
  });

  @override
  void paint(Canvas canvas, Offset start, Offset end,
      {double strokeWidth = 1.0}) {
    // Calculate midpoint of the marriage line
    final Offset midpoint = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2,
    );

    // Calculate perpendicular vector
    double dx = end.dx - start.dx;
    double dy = end.dy - start.dy;
    double length = math.sqrt(dx * dx + dy * dy);

    if (length <= 0) return;

    // Normalize and create perpendicular vector
    dx = dx / length;
    dy = dy / length;
    double perpX = -dy;
    double perpY = dx;

    // Create perpendicular line points
    Offset perp1 = Offset(
      midpoint.dx + perpX * slashLength / 2,
      midpoint.dy + perpY * slashLength / 2,
    );

    Offset perp2 = Offset(
      midpoint.dx - perpX * slashLength / 2,
      midpoint.dy - perpY * slashLength / 2,
    );

    // Paint for divorce line
    final Paint divorcePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth * 1.2
      ..style = PaintingStyle.stroke;

    // Draw perpendicular line
    canvas.drawLine(perp1, perp2, divorcePaint);
  }
}
