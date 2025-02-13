import 'package:flutter/material.dart';
import 'package:org_chart/src/controller.dart';
import 'package:org_chart/src/node.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

abstract class GraphArrowStyle {
  const GraphArrowStyle();
}

/// A graph arrow style that renders a solid arrow using a customizable dash pattern.
class SolidGraphArrow extends GraphArrowStyle {
  const SolidGraphArrow();
}

/// A graph arrow style that renders a dashed arrow using a customizable dash pattern.
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

///The main Painter for drawing the arrows between the nodes.
class EdgePainter<E> extends CustomPainter {
  /// The graph that contains the nodes we want to draw the arrows for.
  OrgChartController<E> controller;

  GraphArrowStyle arrowStyle;

  /// the path of the arrows
  Path linePath = Path();

  double cornerRadius;

  EdgePainter({
    required this.controller,
    required this.linePaint,
    this.cornerRadius = 10,
    required this.arrowStyle,
  });

  /// The paint to draw the arrows with
  Paint linePaint;

  /// returns True if no nodes
  bool allLeaf(List<Node<E>> nodes) {
    return nodes.every((element) =>
        controller.getSubNodes(element).isEmpty || element.hideNodes);
  }

  /// This function is ran recursively to draw the arrows for each node and the nodes below it.
  /// i want to add a border radius to the arrows later on, the commented code is a wrong implementation of that.
  /// There is a lot of things i want to change here, the way the arrows are drawn, style, and animations.
  drawArrows(Node<E> node, Canvas canvas) {
    switch (controller.orientation) {
      case OrgChartOrientation.topToBottom:
        drawArrowsTopToBottom(node, canvas);
        break;
      case OrgChartOrientation.leftToRight:
        drawArrowsLeftToRight(node, canvas);
        break;
    }
  }

  drawArrowsTopToBottom(Node<E> node, Canvas canvas) {
    List<Node<E>> subNodes = controller.getSubNodes(node);
    if (node.hideNodes == false) {
      if (allLeaf(subNodes)) {
        for (int i = 0; i < subNodes.length; i++) {
          Node<E> n = subNodes[i];
          final bool horizontal = n.position.dx > node.position.dx;
          final bool vertical = n.position.dy > node.position.dy;
          final bool c = vertical ? horizontal : !horizontal;

          drawArrow(
              p1: Offset(
                node.position.dx + controller.boxSize.width / 2,
                node.position.dy + controller.boxSize.height / 2,
              ),
              p2: Offset(
                node.position.dx + controller.boxSize.width / 2,
                n.position.dy +
                    controller.boxSize.height / 2 +
                    (vertical ? -1 : 1) * cornerRadius,
              ),
              canvas: canvas);

          if ((n.position.dx - node.position.dx).abs() > cornerRadius) {
            linePath.arcToPoint(
              Offset(
                node.position.dx +
                    controller.boxSize.width / 2 +
                    (horizontal ? 1 : -1) * cornerRadius,
                n.position.dy + controller.boxSize.height / 2,
              ),
              radius: Radius.circular(cornerRadius),
              clockwise: !c,
            );
            drawArrow(
                p1: Offset(
                  node.position.dx +
                      controller.boxSize.width / 2 +
                      (horizontal ? 1 : -1) * cornerRadius,
                  n.position.dy + controller.boxSize.height / 2,
                ),
                p2: Offset(
                  n.position.dx + controller.boxSize.width / 2,
                  n.position.dy + controller.boxSize.height / 2,
                ),
                canvas: canvas);
          }
        }
      } else {
        for (var n in subNodes) {
          final minx = math.min(node.position.dx, n.position.dx);
          final maxx = math.max(node.position.dx, n.position.dx);
          final miny = math.min(node.position.dy, n.position.dy);
          final maxy = math.max(node.position.dy, n.position.dy);

          final dy = (maxy - miny) / 2 + controller.boxSize.height / 2;

          bool horizontal = maxx == node.position.dx;
          bool vertical = maxy == node.position.dy;
          bool clockwise = vertical ? !horizontal : horizontal;

          drawArrow(
            p1: Offset(
              node.position.dx + controller.boxSize.width / 2,
              node.position.dy + controller.boxSize.height / 2,
            ),
            p2: Offset(
              node.position.dx + controller.boxSize.width / 2,
              miny + dy + (vertical ? 1 : -1) * cornerRadius,
            ),
            canvas: canvas,
          );

          if (maxx - minx > cornerRadius * 2) {
            linePath.arcToPoint(
                Offset(
                  node.position.dx +
                      controller.boxSize.width / 2 +
                      (!(horizontal) ? 1 : -1) * cornerRadius,
                  miny + dy,
                ),
                radius: Radius.circular(cornerRadius),
                clockwise: clockwise);

            drawArrow(
              p1: Offset(
                node.position.dx +
                    controller.boxSize.width / 2 +
                    (!(horizontal) ? 1 : -1) * cornerRadius,
                miny + dy,
              ),
              p2: Offset(
                n.position.dx +
                    controller.boxSize.width / 2 +
                    (horizontal ? 1 : -1) * cornerRadius,
                miny + dy,
              ),
              canvas: canvas,
            );
            linePath.arcToPoint(
              Offset(
                n.position.dx + controller.boxSize.width / 2,
                miny + dy + (!vertical ? 1 : -1) * cornerRadius,
              ),
              radius: Radius.circular(cornerRadius),
              clockwise: !clockwise,
            );
          }
          drawArrow(
            p1: maxx - minx <= cornerRadius * 2
                ? Offset(
                    node.position.dx + controller.boxSize.width / 2,
                    miny + dy + (vertical ? 1 : -1) * cornerRadius,
                  )
                : Offset(
                    n.position.dx + controller.boxSize.width / 2,
                    miny + dy + (!vertical ? 1 : -1) * cornerRadius,
                  ),
            p2: Offset(
              n.position.dx + controller.boxSize.width / 2,
              n.position.dy + controller.boxSize.height / 2,
            ),
            canvas: canvas,
          );

          drawArrowsTopToBottom(n, canvas);
        }
      }
    }
  }

  drawArrowsLeftToRight(Node<E> node, Canvas canvas) {
    List<Node<E>> subNodes = controller.getSubNodes(node);
    if (node.hideNodes == false) {
      if (allLeaf(subNodes)) {
        for (int i = 0; i < subNodes.length; i++) {
          Node<E> n = subNodes[i];
          final bool horizontal = n.position.dx > node.position.dx;
          final bool vertical = n.position.dy > node.position.dy;
          final bool c = vertical ? horizontal : !horizontal;

          drawArrow(
              p1: Offset(
                node.position.dx + controller.boxSize.width / 2,
                node.position.dy + controller.boxSize.height / 2,
              ),
              p2: Offset(
                n.position.dx +
                    controller.boxSize.width / 2 +
                    (horizontal ? -1 : 1) * cornerRadius,
                node.position.dy + controller.boxSize.height / 2,
              ),
              canvas: canvas);

          if ((n.position.dy - node.position.dy).abs() > cornerRadius) {
            linePath.arcToPoint(
              Offset(
                n.position.dx + controller.boxSize.width / 2,
                node.position.dy +
                    controller.boxSize.height / 2 +
                    (vertical ? 1 : -1) * cornerRadius,
              ),
              radius: Radius.circular(cornerRadius),
              clockwise: c,
            );
            drawArrow(
                p1: Offset(
                  n.position.dx + controller.boxSize.width / 2,
                  node.position.dy +
                      controller.boxSize.height / 2 +
                      (vertical ? 1 : -1) * cornerRadius,
                ),
                p2: Offset(
                  n.position.dx + controller.boxSize.width / 2,
                  n.position.dy + controller.boxSize.height / 2,
                ),
                canvas: canvas);
          }
        }
      } else {
        for (var n in subNodes) {
          final minx = math.min(node.position.dx, n.position.dx);
          final maxx = math.max(node.position.dx, n.position.dx);
          final miny = math.min(node.position.dy, n.position.dy);
          final maxy = math.max(node.position.dy, n.position.dy);

          final dx = (maxx - minx) / 2 + controller.boxSize.width / 2;

          bool horizontal = maxx == node.position.dx;
          bool vertical = maxy == node.position.dy;

          bool clockwise = horizontal ? !vertical : vertical;

          drawArrow(
            canvas: canvas,
            p1: Offset(
              node.position.dx + controller.boxSize.width / 2,
              node.position.dy + controller.boxSize.height / 2,
            ),
            p2: Offset(minx + dx + (horizontal ? 1 : -1) * cornerRadius,
                node.position.dy + controller.boxSize.height / 2),
          );

          if (maxy - miny > cornerRadius * 2) {
            linePath.arcToPoint(
                Offset(
                  minx + dx,
                  node.position.dy +
                      controller.boxSize.height / 2 +
                      (vertical ? -1 : 1) * cornerRadius,
                ),
                radius: Radius.circular(cornerRadius),
                clockwise: !clockwise);

            drawArrow(
              canvas: canvas,
              p1: Offset(
                minx + dx,
                node.position.dy +
                    controller.boxSize.height / 2 +
                    (vertical ? -1 : 1) * cornerRadius,
              ),
              p2: Offset(
                minx + dx,
                n.position.dy +
                    controller.boxSize.height / 2 +
                    (vertical ? 1 : -1) * cornerRadius,
              ),
            );

            linePath.arcToPoint(
                Offset(
                  minx + dx + (!horizontal ? 1 : -1) * cornerRadius,
                  n.position.dy + controller.boxSize.height / 2,
                ),
                radius: Radius.circular(cornerRadius),
                clockwise: clockwise);
          }
          drawArrow(
            canvas: canvas,
            p1: maxy - miny <= cornerRadius * 2
                ? Offset(minx + dx + (horizontal ? 1 : -1) * cornerRadius,
                    node.position.dy + controller.boxSize.height / 2)
                : Offset(
                    minx + dx + (!horizontal ? 1 : -1) * cornerRadius,
                    n.position.dy + controller.boxSize.height / 2,
                  ),
            p2: Offset(n.position.dx + controller.boxSize.width / 2,
                n.position.dy + controller.boxSize.height / 2),
          );

          drawArrowsLeftToRight(n, canvas);
        }
      }
    }
  }

  drawArrow({
    required Offset p1,
    required Offset p2,
    required Canvas canvas,
  }) {
    switch (arrowStyle) {
      case SolidGraphArrow _:
        linePath.moveTo(p1.dx, p1.dy);
        linePath.lineTo(
          p2.dx,
          p2.dy,
        );
        break;
      case DashedGraphArrow _:
        drawDashedLine(
          p1: p1,
          p2: p2,
          pattern: (arrowStyle as DashedGraphArrow).pattern,
          paint: linePaint,
          canvas: canvas,
          // dashWidth: (arrowStyle as DashedGraphArrow).dashWidth,
          // dashSpace: (arrowStyle as DashedGraphArrow).dashSpace,
        );
        linePath.moveTo(p2.dx, p2.dy);
        break;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    linePath.reset();
    for (var node in controller.roots) {
      drawArrows(node, canvas);
    }

    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  void drawDashedLine({
    required Canvas canvas,
    required Offset p1,
    required Offset p2,
    required Iterable<double> pattern,
    required Paint paint,
  }) {
    assert(pattern.length.isEven);
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
    // linePath.
    canvas.drawPoints(ui.PointMode.lines, points, paint);
  }
}
