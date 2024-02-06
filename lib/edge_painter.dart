import 'package:flutter/material.dart';
import 'package:org_chart/controller.dart';
import 'package:org_chart/node.dart';
// import 'package:org_chart/org_chart.dart';
import 'dart:math' as math;

import 'package:org_chart/org_chart.dart';

///The main Painter for drawing the arrows between the nodes.
class EdgePainter<E> extends CustomPainter {
  /// The graph that contains the nodes we want to draw the arrows for.
  OrgChartController<E> controller;

  /// the path of the arrows
  Path linePath = Path();

  EdgePainter({required this.controller, required this.linePaint}) {
    // print(linePaint);
    // // print(this.linePaint);
    // this.linePaint = linePaint
    // print(linePaint);
    // print(this.linePaint);
  }

  /// The paint to draw the arrows with
  late Paint linePaint;

  /// returns True if no nodes
  bool allLeaf(List<Node<E>> nodes) {
    return nodes.every((element) =>
        controller.getSubNodes(element).isEmpty || element.hideNodes);
  }

  /// This function is called recursively to draw the arrows for each node and the nodes below it.
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
      default:
    }
  }

  drawArrowsTopToBottom(Node<E> node, Canvas canvas) {
    List<Node<E>> subNodes = controller.getSubNodes(node);
    if (node.hideNodes == false) {
      if (allLeaf(subNodes)) {
        for (var n in subNodes) {
          linePath.moveTo(node.position.dx + controller.boxSize.width / 2,
              node.position.dy + controller.boxSize.height / 2);
          linePath.lineTo(
            node.position.dx + controller.boxSize.width / 2,
            n.position.dy + controller.boxSize.height / 2,
          );
          linePath.lineTo(
            n.position.dx + controller.boxSize.width / 2,
            n.position.dy + controller.boxSize.height / 2,
          );
        }
      } else {
        for (var n in subNodes) {
          final minx = math.min(node.position.dx, n.position.dx);
          final maxx = math.max(node.position.dx, n.position.dx);
          final miny = math.min(node.position.dy, n.position.dy);
          final maxy = math.max(node.position.dy, n.position.dy);

          // final dx = (maxx - minx) / 2 + 50;
          final dy = (maxy - miny) / 2 + 50;

          // bool b = maxx == node.position.dx;

          linePath.moveTo(
            node.position.dx + controller.boxSize.width / 2,
            node.position.dy + controller.boxSize.height / 2,
          );

          linePath.lineTo(
            node.position.dx + controller.boxSize.width / 2,
            miny + dy - 10,
          );

          if (maxx - minx > 15) {
            // linePath.arcToPoint(
            //     Offset(node.position.dx + graph.boxSize.width / 2 + (b ? -10 : 10),
            //         miny + dy),
            //     radius: const Radius.circular(10),
            //     clockwise: b);

            linePath.lineTo(
              n.position.dx + controller.boxSize.width / 2,
              miny + dy - 10,
            );
            // + (!b ? -10 : 10)

            // linePath.arcToPoint(
            //     Offset(n.position.dx + graph.boxSize.width / 2, miny + dy + 10),
            //     radius: const Radius.circular(10),
            //     clockwise: !b);
          }

          linePath.lineTo(
            n.position.dx + controller.boxSize.width / 2,
            n.position.dy + controller.boxSize.height / 2,
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
        for (var n in subNodes) {
          linePath.moveTo(
            node.position.dx + controller.boxSize.width / 2,
            node.position.dy + controller.boxSize.height / 2,
          );
          linePath.lineTo(
            n.position.dx + controller.boxSize.width / 2,
            node.position.dy + controller.boxSize.height / 2,
          );
          linePath.lineTo(
            n.position.dx + controller.boxSize.width / 2,
            n.position.dy + controller.boxSize.height / 2,
          );
        }
      } else {
        for (var n in subNodes) {
          final minx = math.min(node.position.dx, n.position.dx);
          final maxx = math.max(node.position.dx, n.position.dx);
          final miny = math.min(node.position.dy, n.position.dy);
          final maxy = math.max(node.position.dy, n.position.dy);

          final dx = (maxx - minx) / 2 +
              85; // TODO: replace this hardcoded 85 value to a variable
          // final dy = (maxy - miny) / 2 +
          //     85; // TODO: replace this hardcoded 85 value to a variable

          // bool b = maxx == node.position.dx;
//////////////////////////////////////
          linePath.moveTo(
            node.position.dx + controller.boxSize.width / 2,
            node.position.dy + controller.boxSize.height / 2,
          );

          linePath.lineTo(
            minx + dx - 10,
            node.position.dy + controller.boxSize.height / 2,
          );

          if (maxy - miny > 15) {
            // linePath.arcToPoint(
            //     Offset(node.position.dx + graph.boxSize.width / 2 + (b ? -10 : 10),
            //         miny + dy),
            //     radius: const Radius.circular(10),
            //     clockwise: b);

            linePath.lineTo(
              minx + dx - 10,
              n.position.dy + controller.boxSize.height / 2,
            );
            // + (!b ? -10 : 10)

            // linePath.arcToPoint(
            //     Offset(n.position.dx + graph.boxSize.width / 2, miny + dy + 10),
            //     radius: const Radius.circular(10),
            //     clockwise: !b);
          }

          linePath.lineTo(
            n.position.dx + controller.boxSize.width,
            n.position.dy + controller.boxSize.height / 2,
          );

          drawArrowsLeftToRight(n, canvas);
        }
      }
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

  void drawDashedLine(
      {required Canvas canvas,
      required Offset p1,
      required Offset p2,
      required int dashWidth,
      required int dashSpace,
      required Paint paint}) {
    // Get normalized distance vector from p1 to p2
    var dx = p2.dx - p1.dx;
    var dy = p2.dy - p1.dy;
    final magnitude = math.sqrt(dx * dx + dy * dy);
    dx = dx / magnitude;
    dy = dy / magnitude;

    // Compute number of dash segments
    final steps = magnitude ~/ (dashWidth + dashSpace);

    var startX = p1.dx;
    var startY = p1.dy;

    for (int i = 0; i < steps; i++) {
      final endX = startX + dx * dashWidth;
      final endY = startY + dy * dashWidth;
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
      startX += dx * (dashWidth + dashSpace);
      startY += dy * (dashWidth + dashSpace);
    }
  }
}
