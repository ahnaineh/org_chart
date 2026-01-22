import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:org_chart/src/base/base_controller.dart';
import 'package:org_chart/src/base/base_graph_constants.dart';

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
  /// The dash pattern defined as alternating lengths of dashes and gaps.
  final Iterable<double> pattern;
  const DashedGraphArrow({
    this.pattern = const [10, 5],
  });
}

/// Connection types for drawing lines between nodes
enum ConnectionType {
  direct,
  twoSegment,
  threeSegment,
  adaptive,
  simpleLeafNode,
  genogramParentChild,
}

/// Line ending types for edge connections
enum LineEndingType {
  arrow,
  circle,
  none,
}

// Constants for arrow and path styling
/// Default corner radius for curved edges
// const double DEFAULT_CORNER_RADIUS = 10.0;

/// Default arrow head length
const double defaultArrowHeadLength = 10.0;

/// Default arrow head angle (30 degrees in radians)
const double defaultArrowHeadAngle = math.pi / 6;

/// Default padding distance for segment extensions
const double defaultSegmentPadding = 20.0;

/// Default minimum distance for determining if nodes are too close
const double defaultNodeProximityThreshold = 1.0;

/// Small epsilon value for collinearity check
const double collinearityEpsilon = 0.0001;

/// Horizontal alignment threshold for centered node detection
const double horizontalCenterThreshold = 0.7;

/// Vertical alignment threshold for centered node detection
const double verticalCenterThreshold = 0.7;

/// Horizontal offset multiplier for side approach
const double horizontalOffsetMultiplier = 0.6;

/// Vertical offset multiplier for top/bottom approach
const double verticalOffsetMultiplier = 0.8;

/// Fixed distance from child node for routing connection
const double fixedDistanceMultiplier =
    BaseGraphConstants.fixedDistanceMultiplier;
// Multiplier to be used with box size

/// Base edge painter class that should be extended by specific graph types
class EdgePainterUtils {
  /// The paint configuration for drawing lines
  final Paint linePaint;

  /// Corner radius for curved edges
  final double cornerRadius;

  /// Arrow/line style configuration
  final GraphArrowStyle arrowStyle;

  /// Line ending type configuration
  final LineEndingType lineEndingType;

  /// Constants for arrow head
  final double arrowHeadLength;
  final double arrowHeadAngle;

  EdgePainterUtils({
    required this.linePaint,
    required this.cornerRadius,
    required this.arrowStyle,
    this.lineEndingType = LineEndingType.arrow,
    this.arrowHeadLength = defaultArrowHeadLength,
    this.arrowHeadAngle = defaultArrowHeadAngle,
  });

  /// Resolve points based on the current text direction.
  List<Offset> resolveDirectionalPoints({
    required List<Offset> points,
    required double width,
    required TextDirection textDirection,
  }) {
    if (textDirection != TextDirection.rtl) return points;
    return points.map((point) => Offset(width - point.dx, point.dy)).toList();
  }

  /// Resolve a single point based on the current text direction.
  Offset resolveDirectionalOffset({
    required Offset offset,
    required double width,
    required TextDirection textDirection,
  }) {
    if (textDirection != TextDirection.rtl) return offset;
    return Offset(width - offset.dx, offset.dy);
  }

  /// Draw a line between two points
  void drawConnection(
    Canvas canvas,
    Offset start,
    Offset end, {
    required Size startSize,
    required Size endSize,
    required GraphOrientation orientation,
    ConnectionType type = ConnectionType.adaptive,
    Paint? paint,
  }) {
    // Use provided paint or default linePaint
    final Paint connectionPaint = paint ?? linePaint;

    // Determine the actual connection type to use
    final ConnectionType actualType = _determineConnectionType(
      type: type,
      start: start,
      end: end,
      orientation: orientation,
    );

    // Generate connection points based on connection type
    final List<Offset> points = _generateConnectionPoints(
      type: actualType,
      start: start,
      end: end,
      startSize: startSize,
      endSize: endSize,
      orientation: orientation,
    );
    // Draw the path with appropriate style
    drawPath(canvas, points, connectionPaint);

    // Draw line ending based on type
    if (points.length >= 2 && lineEndingType != LineEndingType.none) {
      final double angle = vectorAngle(points.last - points[points.length - 2]);

      switch (lineEndingType) {
        case LineEndingType.arrow:
          drawArrowHead(canvas, points.last, angle, connectionPaint);
          break;
        case LineEndingType.circle:
          drawCircleEnd(canvas, points.last, connectionPaint);
          break;
        case LineEndingType.none:
          // No ending decoration
          break;
      }
    }
  }

  /// Draw a connection from precomputed points, including line endings.
  void drawConnectionWithPoints(Canvas canvas, List<Offset> points,
      {Paint? paint}) {
    if (points.length < 2) return;
    final Paint connectionPaint = paint ?? linePaint;

    drawPath(canvas, points, connectionPaint);

    if (lineEndingType == LineEndingType.none) {
      return;
    }

    final double angle = vectorAngle(points.last - points[points.length - 2]);
    switch (lineEndingType) {
      case LineEndingType.arrow:
        drawArrowHead(canvas, points.last, angle, connectionPaint);
        break;
      case LineEndingType.circle:
        drawCircleEnd(canvas, points.last, connectionPaint);
        break;
      case LineEndingType.none:
        break;
    }
  }

  /// Returns the resolved connection type for the given endpoints.
  ConnectionType resolveConnectionType({
    required ConnectionType type,
    required Offset start,
    required Offset end,
    required GraphOrientation orientation,
  }) {
    return _determineConnectionType(
      type: type,
      start: start,
      end: end,
      orientation: orientation,
    );
  }

  /// Returns the list of points used to draw a connection.
  List<Offset> getConnectionPoints({
    required ConnectionType type,
    required Offset start,
    required Offset end,
    required Size startSize,
    required Size endSize,
    required GraphOrientation orientation,
  }) {
    final ConnectionType actualType = _determineConnectionType(
      type: type,
      start: start,
      end: end,
      orientation: orientation,
    );

    return _generateConnectionPoints(
      type: actualType,
      start: start,
      end: end,
      startSize: startSize,
      endSize: endSize,
      orientation: orientation,
    );
  }

  /// Draw path with given points
  void drawPath(Canvas canvas, List<Offset> points, [Paint? paint]) {
    if (points.length < 2) return;

    // Use provided paint or default linePaint
    final Paint pathPaint = paint ?? linePaint;

    // Optimize for common case of straight line
    if (points.length == 2) {
      canvas.drawLine(points.first, points.last, pathPaint);
      return;
    }

    // Draw path based on arrow style
    if (arrowStyle is SolidGraphArrow) {
      _drawSolidPath(canvas, points, pathPaint);
    } else if (arrowStyle is DashedGraphArrow) {
      _drawDashedPath(
          canvas, points, (arrowStyle as DashedGraphArrow).pattern, pathPaint);
    }
  }

  /// Draw a solid path with rounded corners
  void _drawSolidPath(Canvas canvas, List<Offset> points, Paint paint) {
    final Path path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 2; i++) {
      Offset current = points[i];
      Offset next = points[i + 1];
      Offset afterNext = points[i + 2];

      bool isTurn = !_isCollinear(current, next, afterNext);

      if (isTurn && cornerRadius > 0) {
        // Calculate direction vectors
        Offset dir1 = next - current;
        Offset dir2 = afterNext - next;

        // Get vector lengths
        double len1 = dir1.distance;
        double len2 = dir2.distance;

        if (len1 > 0 && len2 > 0) {
          // Normalize vectors
          dir1 = Offset(dir1.dx / len1, dir1.dy / len1);
          dir2 = Offset(dir2.dx / len2, dir2.dy / len2);

          // Calculate curve radius (limited by segment lengths)
          double radius = math.min(cornerRadius, math.min(len1, len2) / 2);

          // Calculate corner points
          Offset beforeCorner = next - dir1 * radius;
          Offset afterCorner = next + dir2 * radius;

          // Draw line to before corner point
          path.lineTo(beforeCorner.dx, beforeCorner.dy);

          // Draw arc around corner
          bool isClockwise = _isClockwise(current, next, afterNext);
          path.arcToPoint(
            afterCorner,
            radius: Radius.circular(radius),
            clockwise: isClockwise,
          );
        } else {
          path.lineTo(next.dx, next.dy);
        }
      } else {
        path.lineTo(next.dx, next.dy);
      }
    } // Draw final segment
    if (points.length >= 2) {
      path.lineTo(points.last.dx, points.last.dy);
    }

    canvas.drawPath(path, paint);
  }

  /// Draw a dashed path with rounded corners
  void _drawDashedPath(Canvas canvas, List<Offset> points,
      Iterable<double> pattern, Paint paint) {
    assert(pattern.length.isEven,
        "Dash pattern must have an even number of elements");

    // Draw straight segments with dashes
    for (int i = 0; i < points.length - 1; i++) {
      Offset start = points[i];
      Offset end = points[i + 1];

      // Draw curved corners if needed
      if (i < points.length - 2 &&
          !_isCollinear(start, end, points[i + 2]) &&
          cornerRadius > 0) {
        // Handle straight segment before corner
        Offset next = points[i + 1];
        Offset afterNext = points[i + 2];

        // Calculate direction vectors
        Offset dir1 = next - start;
        Offset dir2 = afterNext - next;

        // Get vector lengths
        double len1 = dir1.distance;
        double len2 = dir2.distance;

        if (len1 > 0 && len2 > 0) {
          // Normalize vectors
          dir1 = Offset(dir1.dx / len1, dir1.dy / len1);
          dir2 = Offset(dir2.dx / len2, dir2.dy / len2);

          // Calculate curve radius
          double radius = math.min(cornerRadius, math.min(len1, len2) / 2);

          // Calculate corner points
          Offset beforeCorner = next -
              dir1 * radius; // Draw straight dashed segment before corner
          _drawDashedLine(canvas, start, beforeCorner, pattern, paint);

          // Create arc path for the corner
          Path arcPath = Path()
            ..moveTo(beforeCorner.dx, beforeCorner.dy)
            ..arcToPoint(
              next + dir2 * radius,
              radius: Radius.circular(radius),
              clockwise: _isClockwise(start, next, afterNext),
            );

          // Draw dashed arc
          _drawDashedCurve(canvas, arcPath.computeMetrics(), pattern, paint);
        } else {
          _drawDashedLine(canvas, start, end, pattern, paint);
        }
      } else {
        _drawDashedLine(canvas, start, end, pattern, paint);
      }
    }
  }

  /// Draw a dashed line between two points
  void _drawDashedLine(Canvas canvas, Offset start, Offset end,
      Iterable<double> pattern, Paint paint) {
    // Calculate the total length of the line
    final double distance = (end - start).distance;
    if (distance <= 0) return;

    // Scale dash pattern to the distance
    final List<double> normalizedPattern =
        pattern.map((width) => width / distance).toList();

    // Create points for each dash segment
    final List<Offset> points = [];
    double t = 0;
    int i = 0;

    while (t < 1) {
      // Add point at start of dash
      points.add(Offset.lerp(start, end, t)!);

      // Move forward by dash width
      t += normalizedPattern[i++];
      t = t.clamp(0, 1);

      // Add point at end of dash
      points.add(Offset.lerp(start, end, t)!);

      // Move forward by gap width
      t += normalizedPattern[i++];

      // Reset pattern index if needed
      i %= normalizedPattern.length;
    }

    // Draw all dash segments
    canvas.drawPoints(ui.PointMode.lines, points, paint);
  }

  /// Draw a dashed curve along a path
  void _drawDashedCurve(Canvas canvas, ui.PathMetrics pathMetrics,
      Iterable<double> pattern, Paint paint) {
    for (final metric in pathMetrics) {
      double distance = 0;
      bool draw = true;
      int patternIndex = 0;

      while (distance < metric.length) {
        final double segmentLength = pattern.elementAt(patternIndex);
        patternIndex = (patternIndex + 1) % pattern.length;

        if (draw) {
          final double segmentStart = distance;
          final double segmentEnd =
              math.min(distance + segmentLength, metric.length);

          if (segmentStart < metric.length) {
            final Path dashPath = metric.extractPath(segmentStart, segmentEnd);
            canvas.drawPath(dashPath, paint);
          }
        }

        distance += segmentLength;
        draw = !draw; // Toggle between dash and gap
      }
    }
  }

  /// Draw an arrow head at the specified position
  void drawArrowHead(Canvas canvas, Offset tip, double angle, Paint paint) {
    // Precompute trig values for better performance
    final double cosAngleMinus = math.cos(angle - arrowHeadAngle);
    final double sinAngleMinus = math.sin(angle - arrowHeadAngle);
    final double cosAnglePlus = math.cos(angle + arrowHeadAngle);
    final double sinAnglePlus = math.sin(angle + arrowHeadAngle);

    final Offset p1 = tip -
        Offset(
          arrowHeadLength * cosAngleMinus,
          arrowHeadLength * sinAngleMinus,
        );

    final Offset p2 = tip -
        Offset(
          arrowHeadLength * cosAnglePlus,
          arrowHeadLength * sinAnglePlus,
        );

    // Draw both arrow head lines at once using a path for better performance
    final Path arrowPath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(p1.dx, p1.dy)
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(p2.dx, p2.dy);

    canvas.drawPath(arrowPath, paint);
  }

  /// Draw a circle at the end of the line
  void drawCircleEnd(Canvas canvas, Offset center, Paint paint) {
    // Draw filled circle
    canvas.drawCircle(center, arrowHeadLength / 2, paint);

    // Draw circle outline for better visibility
    final Paint outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = paint.strokeWidth
      ..color = paint.color;
    canvas.drawCircle(center, arrowHeadLength / 2, outlinePaint);
  }

  /// Calculate the angle of a vector
  double vectorAngle(Offset vector) => math.atan2(vector.dy, vector.dx);

  /// Check if three points are collinear (form a straight line)
  bool _isCollinear(Offset p1, Offset p2, Offset p3) {
    // Use cross product to check collinearity
    final double crossProduct =
        (p2.dx - p1.dx) * (p3.dy - p2.dy) - (p2.dy - p1.dy) * (p3.dx - p2.dx);

    return crossProduct.abs() < collinearityEpsilon;
  }

  /// Determine if the turn is clockwise
  bool _isClockwise(Offset p1, Offset p2, Offset p3) {
    double crossProduct =
        (p2.dx - p1.dx) * (p3.dy - p2.dy) - (p2.dy - p1.dy) * (p3.dx - p2.dx);
    return crossProduct > 0;
  }

  /// Determine the actual connection type based on layout and positions
  ConnectionType _determineConnectionType({
    required ConnectionType type,
    required Offset start,
    required Offset end,
    required GraphOrientation orientation,
  }) {
    if (type != ConnectionType.adaptive) {
      return type;
    }

    // Check if special routing is needed
    final bool needsSpecialRouting = orientation == GraphOrientation.topToBottom
        ? end.dy < start.dy + defaultSegmentPadding
        : end.dx < start.dx + defaultSegmentPadding;

    return needsSpecialRouting
        ? ConnectionType.adaptive
        : ConnectionType.threeSegment;
  }

  /// Generate connection points based on the connection type
  List<Offset> _generateConnectionPoints({
    required ConnectionType type,
    required Offset start,
    required Offset end,
    required Size startSize,
    required Size endSize,
    required GraphOrientation orientation,
  }) {
    switch (type) {
      case ConnectionType.direct:
        return _generateDirectPoints(start, end);

      case ConnectionType.twoSegment:
        return _generateTwoSegmentPoints(start, end, orientation);

      case ConnectionType.threeSegment:
        return _generateThreeSegmentPoints(start, end, orientation);

      case ConnectionType.simpleLeafNode:
        return _generateSimpleLeafNodePoints(
          start: start,
          end: end,
          startSize: startSize,
          endSize: endSize,
          orientation: orientation,
        );

      case ConnectionType.adaptive:
        return _generateAdaptivePoints(
          start: start,
          end: end,
          startSize: startSize,
          endSize: endSize,
          orientation: orientation,
        );

      case ConnectionType.genogramParentChild:
        return _generateGenogramParentChildPoints(
          start: start,
          end: end,
          startSize: startSize,
          endSize: endSize,
          orientation: orientation,
        );
    }
  }

  /// Generate points for direct connection
  List<Offset> _generateDirectPoints(Offset start, Offset end) {
    return [start, end];
  }

  /// Generate points for two-segment connection
  List<Offset> _generateTwoSegmentPoints(
    Offset start,
    Offset end,
    GraphOrientation orientation,
  ) {
    final Offset midPoint = orientation == GraphOrientation.topToBottom
        ? Offset(start.dx, (start.dy + end.dy) / 2)
        : Offset((start.dx + end.dx) / 2, start.dy);
    return [start, midPoint, end];
  }

  /// Generate points for three-segment connection
  List<Offset> _generateThreeSegmentPoints(
    Offset start,
    Offset end,
    GraphOrientation orientation,
  ) {
    if (orientation == GraphOrientation.topToBottom) {
      final double midY = (start.dy + end.dy) / 2;
      return [
        start,
        Offset(start.dx, midY),
        Offset(end.dx, midY),
        end,
      ];
    } else {
      final double midX = (start.dx + end.dx) / 2;
      return [
        start,
        Offset(midX, start.dy),
        Offset(midX, end.dy),
        end,
      ];
    }
  }

  /// Generate points for genogram parent-child connection
  /// This adds extra vertical drop (half startSize height) from the marriage line
  List<Offset> _generateGenogramParentChildPoints({
    required Offset start,
    required Offset end,
    required Size startSize,
    required Size endSize,
    required GraphOrientation orientation,
  }) {
    if (orientation == GraphOrientation.topToBottom) {
      // Add half startSize height to the first segment for extra vertical drop
      final double firstDropY = start.dy + (startSize.height / 2);
      final double midY = (firstDropY + end.dy) / 2;
      return [
        start,
        Offset(start.dx, midY),
        Offset(end.dx, midY),
        end,
      ];
    } else {
      // Add half startSize width to the first segment for horizontal orientation
      final double firstDropX = start.dx + (startSize.width / 2);
      final double midX = (firstDropX + end.dx) / 2;
      return [
        start,
        Offset(midX, start.dy),
        Offset(midX, end.dy),
        end,
      ];
    }
  }

  /// Generate points for simple leaf node connection
  List<Offset> _generateSimpleLeafNodePoints({
    required Offset start,
    required Offset end,
    required Size startSize,
    required Size endSize,
    required GraphOrientation orientation,
  }) {
    if (orientation == GraphOrientation.topToBottom) {
      return _generateVerticalSimpleLeafNodePoints(
        start: start,
        end: end,
        startSize: startSize,
        endSize: endSize,
      );
    } else {
      return _generateHorizontalSimpleLeafNodePoints(
        start: start,
        end: end,
        startSize: startSize,
        endSize: endSize,
      );
    }
  }

  /// Generate points for vertical simple leaf node connection
  List<Offset> _generateVerticalSimpleLeafNodePoints({
    required Offset start,
    required Offset end,
    required Size startSize,
    required Size endSize,
  }) {
    final bool needsSpecialRouting = end.dy < start.dy + defaultSegmentPadding;

    if (needsSpecialRouting) {
      return _generateVerticalSimpleLeafNodeSpecialRouting(
        start: start,
        end: end,
        startSize: startSize,
        endSize: endSize,
      );
    } else {
      return _generateVerticalSimpleLeafNodeStandardRouting(
        start: start,
        end: end,
        startSize: startSize,
        endSize: endSize,
      );
    }
  }

  /// Generate points for vertical simple leaf node with special routing
  List<Offset> _generateVerticalSimpleLeafNodeSpecialRouting({
    required Offset start,
    required Offset end,
    required Size startSize,
    required Size endSize,
  }) {
    final Offset p1 = start;
    final Offset p2 = Offset(
      start.dx,
      start.dy + startSize.height / 2 + defaultSegmentPadding,
    );

    final bool nodesTooClose =
        (start.dx - end.dx).abs() - defaultSegmentPadding - cornerRadius <
            _maxWidth(startSize, endSize) * defaultNodeProximityThreshold;

    final double horizontalDir = nodesTooClose
        ? (end.dx < start.dx ? -1 : 1)
        : (end.dx > start.dx ? 1 : -1);

    final double horizontalDist = (start.dx - end.dx).abs() / 2 +
        (!nodesTooClose
            ? 0
            : (_maxWidth(startSize, endSize) / 2 +
                    (end.dx - start.dx).abs() / 2) +
                defaultSegmentPadding);
    end = end +
        Offset(
          (nodesTooClose ? 1 : -1) *
              horizontalDir *
              (endSize.width / 2),
          0,
        );

    return [
      p1,
      p2,
      Offset(start.dx + horizontalDir * horizontalDist, p2.dy),
      Offset(start.dx + horizontalDir * horizontalDist, end.dy),
      end,
    ];
  }

  /// Generate points for vertical simple leaf node with standard routing
  List<Offset> _generateVerticalSimpleLeafNodeStandardRouting({
    required Offset start,
    required Offset end,
    required Size startSize,
    required Size endSize,
  }) {
    final double verticalDrop = defaultSegmentPadding;
    final double horizontalDir = end.dx < start.dx ? 1.0 : -1.0;

    final Offset p2 = Offset(start.dx, start.dy + verticalDrop);
    final Offset p3 = Offset(
      end.dx + horizontalDir * (endSize.width / 2 + defaultSegmentPadding),
      p2.dy,
    );
    end = end +
        Offset(
          horizontalDir * (endSize.width / 2),
          0,
        );
    final Offset p4 = Offset(p3.dx, end.dy);

    return [start, p2, p3, p4, end];
  }

  /// Generate points for horizontal simple leaf node connection
  List<Offset> _generateHorizontalSimpleLeafNodePoints({
    required Offset start,
    required Offset end,
    required Size startSize,
    required Size endSize,
  }) {
    final bool needsSpecialRouting = end.dx < start.dx + defaultSegmentPadding;

    if (needsSpecialRouting) {
      return _generateHorizontalSimpleLeafNodeSpecialRouting(
        start: start,
        end: end,
        startSize: startSize,
        endSize: endSize,
      );
    } else {
      return _generateHorizontalSimpleLeafNodeStandardRouting(
        start: start,
        end: end,
        startSize: startSize,
        endSize: endSize,
      );
    }
  }

  /// Generate points for horizontal simple leaf node with special routing
  List<Offset> _generateHorizontalSimpleLeafNodeSpecialRouting({
    required Offset start,
    required Offset end,
    required Size startSize,
    required Size endSize,
  }) {
    final Offset p1 = start;
    final Offset p2 = Offset(
      start.dx + startSize.width / 2 + defaultSegmentPadding,
      start.dy,
    );

    final bool nodesTooClose =
        (start.dy - end.dy).abs() - defaultSegmentPadding - cornerRadius <
            _maxHeight(startSize, endSize) * defaultNodeProximityThreshold;

    final double verticalDir = nodesTooClose
        ? (end.dy < start.dy ? -1 : 1)
        : (end.dy > start.dy ? 1 : -1);

    final double verticalDist = (start.dy - end.dy).abs() / 2 +
        (!nodesTooClose
            ? 0
            : (_maxHeight(startSize, endSize) / 2 +
                    (end.dy - start.dy).abs() / 2) +
                defaultSegmentPadding);
    end = end +
        Offset(
          0,
          (nodesTooClose ? 1 : -1) * verticalDir * (endSize.height / 2),
        );

    return [
      p1,
      p2,
      Offset(p2.dx, start.dy + verticalDir * verticalDist),
      Offset(end.dx, start.dy + verticalDir * verticalDist),
      end,
    ];
  }

  /// Generate points for horizontal simple leaf node with standard routing
  List<Offset> _generateHorizontalSimpleLeafNodeStandardRouting({
    required Offset start,
    required Offset end,
    required Size startSize,
    required Size endSize,
  }) {
    final double horizontalDrop = defaultSegmentPadding;
    final double verticalDir = end.dy < start.dy ? 1.0 : -1.0;

    final Offset p2 = Offset(start.dx + horizontalDrop, start.dy);
    final Offset p3 = Offset(
      p2.dx,
      end.dy + verticalDir * (endSize.height / 2 + defaultSegmentPadding),
    );
    end = end +
        Offset(
          0,
          verticalDir * (endSize.height / 2),
        );
    final Offset p4 = Offset(end.dx, p3.dy);

    return [start, p2, p3, p4, end];
  }

  /// Generate points for adaptive connection
  List<Offset> _generateAdaptivePoints({
    required Offset start,
    required Offset end,
    required Size startSize,
    required Size endSize,
    required GraphOrientation orientation,
  }) {
    if (orientation == GraphOrientation.topToBottom) {
      return _generateVerticalAdaptivePoints(
        start: start,
        end: end,
        startSize: startSize,
        endSize: endSize,
      );
    } else {
      return _generateHorizontalAdaptivePoints(
        start: start,
        end: end,
        startSize: startSize,
        endSize: endSize,
      );
    }
  }

  /// Generate points for vertical adaptive connection
  List<Offset> _generateVerticalAdaptivePoints({
    required Offset start,
    required Offset end,
    required Size startSize,
    required Size endSize,
  }) {
    final Offset p1 = start;
    final Offset p2 = Offset(
      start.dx,
      start.dy + startSize.height / 2 + defaultSegmentPadding,
    );

    final bool nodesTooClose = (start.dx - end.dx).abs() <
        _maxWidth(startSize, endSize) * defaultNodeProximityThreshold;

    final double horizontalDir = nodesTooClose
        ? (end.dx < start.dx ? -1 : 1)
        : (end.dx > start.dx ? 1 : -1);

    final double horizontalDist = (start.dx - end.dx).abs() / 2 +
        (!nodesTooClose
            ? 0
            : (_maxWidth(startSize, endSize) / 2 +
                    (end.dx - start.dx).abs() / 2) +
                defaultSegmentPadding);

    return [
      p1,
      p2,
      Offset(start.dx + horizontalDir * horizontalDist, p2.dy),
      Offset(
        start.dx + horizontalDir * horizontalDist,
        end.dy - endSize.height / 2 - defaultSegmentPadding,
      ),
      Offset(end.dx, end.dy - endSize.height / 2 - defaultSegmentPadding),
      end,
    ];
  }

  /// Generate points for horizontal adaptive connection
  List<Offset> _generateHorizontalAdaptivePoints({
    required Offset start,
    required Offset end,
    required Size startSize,
    required Size endSize,
  }) {
    final Offset p1 = start;
    final Offset p2 = Offset(
      start.dx + startSize.width / 2 + defaultSegmentPadding,
      start.dy,
    );

    final bool nodesTooClose = (start.dy - end.dy).abs() <
        _maxHeight(startSize, endSize) * defaultNodeProximityThreshold;

    final double verticalDir = nodesTooClose
        ? (end.dy < start.dy ? -1 : 1)
        : (end.dy > start.dy ? 1 : -1);

    final double verticalDist = (start.dy - end.dy).abs() / 2 +
        (!nodesTooClose
            ? 0
            : (_maxHeight(startSize, endSize) / 2 +
                    (end.dy - start.dy).abs() / 2) +
                defaultSegmentPadding);

    return [
      p1,
      p2,
      Offset(p2.dx, start.dy + verticalDir * verticalDist),
      Offset(
        end.dx - endSize.width / 2 - defaultSegmentPadding,
        start.dy + verticalDir * verticalDist,
      ),
      Offset(end.dx - endSize.width / 2 - defaultSegmentPadding, end.dy),
      end,
    ];
  }

  double _maxWidth(Size a, Size b) => math.max(a.width, b.width);

  double _maxHeight(Size a, Size b) => math.max(a.height, b.height);
}
