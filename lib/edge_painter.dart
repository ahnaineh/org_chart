
import 'package:flutter/material.dart';
import 'package:org_chart/graph.dart';
import 'package:org_chart/node.dart';
// import 'package:org_chart/org_chart.dart';
import 'dart:math' as math;


///The main Painter for drawing the arrows between the nodes.
class EdgePainter<E> extends CustomPainter {
  /// The graph that contains the nodes we want to draw the arrows for.
  Graph<E> graph;

  /// the path to draw thew arrows with, we can add styling here later on.
  Path linePath = Path();
  EdgePainter({required this.graph});
  
  /// returns True if no nodes 
  bool allLeaf(List<Node<E>> nodes) {
    return nodes
        .every((element) => graph.getSubNodes(element).isEmpty || element.hideNodes);
  }

  
  /// This function is called recursively to draw the arrows for each node and the nodes below it.
  /// i want to add a border radius to the arrows later on, the commented code is a wrong implementation of that.
  /// There is a lot of things i want to change here, the way the arrows are drawn, style, and animations.
  drawArrows(Node<E> node) {
    List<Node<E>> subNodes = graph.getSubNodes(node);
    if (node.hideNodes == false) {
      if (allLeaf(subNodes)) {
        for (var n in subNodes) {
          linePath.moveTo(node.position.dx + graph.boxSize.width / 2,
              node.position.dy + graph.boxSize.height / 2);
          linePath.lineTo(node.position.dx + graph.boxSize.width / 2,
              n.position.dy + graph.boxSize.height / 2);
          linePath.lineTo(n.position.dx + graph.boxSize.width / 2,
              n.position.dy + graph.boxSize.height / 2);
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

          linePath.moveTo(node.position.dx + graph.boxSize.width / 2,
              node.position.dy + graph.boxSize.height);

          linePath.lineTo(
              node.position.dx + graph.boxSize.width / 2, miny + dy);

          if (maxx - minx > 15) {
            // linePath.arcToPoint(
            //     Offset(node.position.dx + graph.boxSize.width / 2 + (b ? -10 : 10),
            //         miny + dy),
            //     radius: const Radius.circular(10),
            //     clockwise: b);

            linePath.lineTo(n.position.dx + graph.boxSize.width / 2, miny + dy);
            // + (!b ? -10 : 10)

            // linePath.arcToPoint(
            //     Offset(n.position.dx + graph.boxSize.width / 2, miny + dy + 10),
            //     radius: const Radius.circular(10),
            //     clockwise: !b);
          }

          linePath.lineTo(n.position.dx + graph.boxSize.width / 2,
              n.position.dy + graph.boxSize.height / 2);

          drawArrows(n);
        }
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    var edgePaint = (Paint()
      ..color = Colors.black
      ..strokeWidth = 3)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    linePath.reset();
    for (var node in graph.roots) {
      drawArrows(node);
    }

    canvas.drawPath(linePath, edgePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
