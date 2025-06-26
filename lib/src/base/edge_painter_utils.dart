import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:org_chart/src/base/base_controller.dart';

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
const double fixedDistanceMultiplier = 0.4;
// Multiplier to be used with box size

/// Base edge painter class that should be extended by specific graph types
class EdgePainterUtils {
  /// The paint configuration for drawing lines
  final Paint linePaint;

  /// Corner radius for curved edges
  final double cornerRadius;

  /// Arrow/line style configuration
  final GraphArrowStyle arrowStyle;

  /// Constants for arrow head
  final double arrowHeadLength;
  final double arrowHeadAngle;

  EdgePainterUtils({
    required this.linePaint,
    required this.cornerRadius,
    required this.arrowStyle,
    this.arrowHeadLength = defaultArrowHeadLength,
    this.arrowHeadAngle = defaultArrowHeadAngle,
  });

  /// Draw a line between two points
  void drawConnection(Canvas canvas, Offset start, Offset end, Size boxSize,
      GraphOrientation orientation,
      {ConnectionType type = ConnectionType.adaptive, Paint? paint}) {
    // Use provided paint or default linePaint
    final Paint connectionPaint = paint ?? linePaint;

    // If using adaptive connection type, determine the best connection strategy
    if (type == ConnectionType.adaptive) {
      bool needsSpecialRouting = false;

      if (orientation == GraphOrientation.topToBottom) {
        // Check if end node is above start node (requires special routing)
        needsSpecialRouting = end.dy < start.dy + boxSize.height;
      } else {
        // Check if end node is to the left of start node (requires special routing)
        needsSpecialRouting = end.dx < start.dx + boxSize.width;
      }

      // Choose appropriate connection type based on layout
      type = needsSpecialRouting
          ? ConnectionType.adaptive
          : ConnectionType.threeSegment;
    }

    // Generate connection points based on connection type
    List<Offset> points = [];
    switch (type) {
      case ConnectionType.direct:
        points = [start, end];
        break;

      case ConnectionType.twoSegment:
        final Offset midPoint = orientation == GraphOrientation.topToBottom
            ? Offset(start.dx, (start.dy + end.dy) / 2)
            : Offset((start.dx + end.dx) / 2, start.dy);
        points = [start, midPoint, end];
        break;

      case ConnectionType.threeSegment:
        if (orientation == GraphOrientation.topToBottom) {
          final double midY = (start.dy + end.dy) / 2;
          points = [
            start,
            Offset(start.dx, midY),
            Offset(end.dx, midY),
            end,
          ];
        } else {
          final double midX = (start.dx + end.dx) / 2;
          points = [
            start,
            Offset(midX, start.dy),
            Offset(midX, end.dy),
            end,
          ];
        }
        break;
      case ConnectionType.simpleLeafNode:
        // For the simple leaf node connection, we draw a line from parent
        // and then a line to the child, handling special case when child is above parent
        if (orientation == GraphOrientation.topToBottom) {
          // For vertical layouts (top-to-bottom)
          bool needsSpecialRouting =
              end.dy < start.dy + boxSize.height / 2 + defaultSegmentPadding;

          if (needsSpecialRouting) {
            // Handle case where child is above parent (similar to adaptive)
            final Offset p1 = start;
            final Offset p2 = Offset(start.dx,
                start.dy + boxSize.height / 2 + defaultSegmentPadding);
            final bool nodesTooClose = (start.dx - end.dx).abs() -
                    defaultSegmentPadding -
                    cornerRadius <
                boxSize.width * defaultNodeProximityThreshold;

            final double horizontalDir = nodesTooClose
                ? (end.dx < start.dx ? -1 : 1)
                : (end.dx > start.dx ? 1 : -1);
            final double horizontalDist = (start.dx - end.dx).abs() / 2 +
                (!nodesTooClose
                    ? 0
                    : (boxSize.width / 2 + (end.dx - start.dx).abs() / 2) +
                        defaultSegmentPadding);

            // Calculate points to ensure the arrow ends at the side of the child box
            points = [
              p1,
              p2,
              Offset(start.dx + horizontalDir * horizontalDist, p2.dy),
              Offset(start.dx + horizontalDir * horizontalDist, end.dy),
              Offset(end.dx, end.dy)
            ];
          } else {
            // Standard case where child is below parent
            // Get the fixed vertical drop distance from parent
            final double verticalDrop =
                boxSize.height / 2 + defaultSegmentPadding;

            // Calculate horizontal direction to approach the child
            // If child is to the left of parent, approach from right side of child
            // If child is to the right of parent, approach from left side of child
            final double horizontalDir = end.dx < start.dx ? 1.0 : -1.0;

            // Start by moving down from parent center
            final Offset p2 = Offset(start.dx, start.dy + verticalDrop);

            // Move horizontally to the column boundary (near child's column)
            final Offset p3 = Offset(
                end.dx +
                    horizontalDir *
                        (boxSize.width / 2 + defaultSegmentPadding),
                p2.dy);

            // Move vertically to the height of child's center
            final Offset p4 = Offset(p3.dx, end.dy);

            // Connect to child's side
            points = [
              start, // Parent center
              p2, // Vertical drop from parent
              p3, // Horizontal run to column boundary
              p4, // Vertical to child height
              end // Child center
            ];
          }
        } else {
          // For horizontal layouts (left-to-right)
          bool needsSpecialRouting = end.dx < start.dx;

          if (needsSpecialRouting) {
            // Handle case where child is to the left of parent
            final Offset p1 = start;
            final Offset p2 = Offset(
                start.dx + boxSize.width / 2 + defaultSegmentPadding,
                start.dy);
            final bool nodesTooClose = (start.dy - end.dy).abs() <
                boxSize.height * defaultNodeProximityThreshold;

            final double verticalDir = nodesTooClose
                ? (end.dy < start.dy ? -1 : 1)
                : (end.dy > start.dy ? 1 : -1);

            final double verticalDist = (start.dy - end.dy).abs() / 2 +
                (!nodesTooClose
                    ? 0
                    : (boxSize.height / 2 + (end.dy - start.dy).abs() / 2) +
                        defaultSegmentPadding);

            points = [
              p1,
              p2,
              Offset(p2.dx, start.dy + verticalDir * verticalDist),
              Offset(end.dx - boxSize.width / 2 - defaultSegmentPadding,
                  start.dy + verticalDir * verticalDist),
              Offset(
                  end.dx - boxSize.width / 2 - defaultSegmentPadding, end.dy),
              end
            ];
          } else {
            // Standard case where child is to the right of parent
            // Check if nodes are closely aligned vertically (centered)
            final bool isVerticallyCentered = (start.dy - end.dy).abs() <
                boxSize.height *
                    verticalCenterThreshold; // Use wider threshold to catch near-centered cases

            if (isVerticallyCentered) {
              // For centered nodes, create a path that goes right, then vertically around,
              // and finally approaches from top/bottom

              // Determine which side to approach from (top/bottom)
              final double verticalDir = end.dy <= start.dy
                  ? -1.0
                  : 1.0; // Calculate horizontal point at a fixed distance from the child node
              final double fixedDistanceFromChild =
                  boxSize.width * fixedDistanceMultiplier +
                      defaultSegmentPadding;
              final double horizontalPoint = end.dx - fixedDistanceFromChild;
              // Calculate vertical offset to ensure we're clear of the node
              final double verticalOffset =
                  boxSize.height * verticalOffsetMultiplier;

              points = [
                start, // Start from parent
                Offset(horizontalPoint,
                    start.dy), // Go right to the fixed distance point
                Offset(horizontalPoint,
                    end.dy + verticalDir * verticalOffset), // Turn vertically
                Offset(
                    end.dx,
                    end.dy +
                        verticalDir *
                            verticalOffset), // Approach the side of the child
                end // Connect to child
              ];
            } else {
              // Standard straight-across routing for non-centered nodes
              final Offset horizontalEndPoint = Offset(end.dx, start.dy);
              points = [start, horizontalEndPoint, end];
            }
          }
        }
        break;

      case ConnectionType.adaptive:
        // Generate complex route for special cases
        if (orientation == GraphOrientation.topToBottom) {
          // For case where end's top is above start's bottom
          final Offset p1 = start;
          final Offset p2 = Offset(start.dx,
              start.dy + boxSize.height / 2 + defaultSegmentPadding);
          final bool nodesTooClose = (start.dx - end.dx).abs() <
              boxSize.width * defaultNodeProximityThreshold;

          final double horizontalDir = nodesTooClose
              ? (end.dx < start.dx ? -1 : 1)
              : (end.dx > start.dx ? 1 : -1);

          final double horizontalDist = (start.dx - end.dx).abs() / 2 +
              (!nodesTooClose
                  ? 0
                  : (boxSize.width / 2 + (end.dx - start.dx).abs() / 2) +
                      defaultSegmentPadding);

          points = [
            p1,
            p2,
            Offset(start.dx + horizontalDir * horizontalDist, p2.dy),
            Offset(start.dx + horizontalDir * horizontalDist,
                end.dy - boxSize.height / 2 - defaultSegmentPadding),
            Offset(
                end.dx, end.dy - boxSize.height / 2 - defaultSegmentPadding),
            end
          ];
        } else {
          // For case where end's left is to the left of start's left
          final Offset p1 = start;
          final Offset p2 = Offset(
              start.dx + boxSize.width / 2 + defaultSegmentPadding, start.dy);
          final bool nodesTooClose = (start.dy - end.dy).abs() <
              boxSize.height * defaultNodeProximityThreshold;

          final double verticalDir = nodesTooClose
              ? (end.dy < start.dy ? -1 : 1)
              : (end.dy > start.dy ? 1 : -1);

          final double verticalDist = (start.dy - end.dy).abs() / 2 +
              (!nodesTooClose
                  ? 0
                  : (boxSize.height / 2 + (end.dy - start.dy).abs() / 2) +
                      defaultSegmentPadding);

          points = [
            p1,
            p2,
            Offset(p2.dx, start.dy + verticalDir * verticalDist),
            Offset(end.dx - boxSize.width / 2 - defaultSegmentPadding,
                start.dy + verticalDir * verticalDist),
            Offset(
                end.dx - boxSize.width / 2 - defaultSegmentPadding, end.dy),
            end
          ];
        }
        break;
    } // Adjust the last segment to stop at the edge of the box
    if (points.length >= 2) {
      // Get the direction of the last segment
      Offset lastDirection = points.last - points[points.length - 2];

      // Normalize the direction vector
      double lastSegmentLength = lastDirection.distance;
      if (lastSegmentLength > 0) {
        Offset normalizedDirection = Offset(
            lastDirection.dx / lastSegmentLength,
            lastDirection.dy / lastSegmentLength);

        // Check if the last segment is primarily vertical or horizontal
        bool isVertical =
            normalizedDirection.dy.abs() > normalizedDirection.dx.abs();

        // Calculate how much to shorten the last segment
        double shortenBy = isVertical ? boxSize.height / 2 : boxSize.width / 2;

        // Ensure we don't shorten more than the segment length
        shortenBy = math.min(shortenBy, lastSegmentLength - 1);

        // Only shorten if there's enough length
        if (shortenBy > 0) {
          // Create the new endpoint
          Offset newEndpoint = points.last - normalizedDirection * shortenBy;
          points[points.length - 1] = newEndpoint;
        }
      }
    }

    // Draw the path with appropriate style
    drawPath(canvas, points, connectionPaint);

    // Draw arrow head
    if (points.length >= 2) {
      drawArrowHead(
          canvas,
          points.last,
          vectorAngle(points.last - points[points.length - 2]),
          connectionPaint);
    }
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
}
