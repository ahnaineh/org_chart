import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:org_chart/src/common/edge_painter.dart';
import 'package:org_chart/src/common/node.dart';
import 'package:org_chart/src/controllers/genogram_controller.dart';
import 'package:org_chart/src/controllers/org_chart_controller.dart';

/// Edge painter specific to organizational charts
class GenogramEdgePainter<E> extends BaseEdgePainter<E> {
  /// The org chart controller
  final GenogramController<E> controller;

  GenogramEdgePainter({
    required this.controller,
    required Paint linePaint,
    double cornerRadius = 10,
    required GraphArrowStyle arrowStyle,
  }) : super(
          controller: controller,
          linePaint: linePaint,
          cornerRadius: cornerRadius,
          arrowStyle: arrowStyle,
        );
        
          @override
          void drawNodeConnections(Node<E> node, Canvas canvas) {
            // TODO: implement drawNodeConnections
          }

//   @override
//   void drawNodeConnections(Node<E> node, Canvas canvas) {
//     switch (controller.orientation) {
//       case OrgChartOrientation.topToBottom:
//         drawArrowsTopToBottom(node, canvas);
//         break;
//       case OrgChartOrientation.leftToRight:
//         drawArrowsLeftToRight(node, canvas);
//         break;
//     }
//   }

//   /// Checks if all nodes are leaf nodes (no children or hidden children)
//   bool allLeaf(List<Node<E>> nodes) {
//     return nodes.every((element) =>
//         controller.getSubNodes(element).isEmpty || element.hideNodes);
//   }

//   /// Draw arrows for top-to-bottom oriented org chart
//   void drawArrowsTopToBottom(Node<E> node, Canvas canvas) {
//     List<Node<E>> subNodes = controller.getSubNodes(node);
//     if (node.hideNodes == false) {
//       if (allLeaf(subNodes)) {
//         for (int i = 0; i < subNodes.length; i++) {
//           Node<E> n = subNodes[i];
//           final bool horizontal = n.position.dx > node.position.dx;
//           final bool vertical = n.position.dy > node.position.dy;
//           final bool c = vertical ? horizontal : !horizontal;

//           drawArrow(
//               p1: Offset(
//                 node.position.dx + controller.boxSize.width / 2,
//                 node.position.dy + controller.boxSize.height / 2,
//               ),
//               p2: Offset(
//                 node.position.dx + controller.boxSize.width / 2,
//                 n.position.dy +
//                     controller.boxSize.height / 2 +
//                     (vertical ? -1 : 1) * cornerRadius,
//               ),
//               canvas: canvas);

//           if ((n.position.dx - node.position.dx).abs() > cornerRadius) {
//             linePath.arcToPoint(
//               Offset(
//                 node.position.dx +
//                     controller.boxSize.width / 2 +
//                     (horizontal ? 1 : -1) * cornerRadius,
//                 n.position.dy + controller.boxSize.height / 2,
//               ),
//               radius: Radius.circular(cornerRadius),
//               clockwise: !c,
//             );
//             drawArrow(
//                 p1: Offset(
//                   node.position.dx +
//                       controller.boxSize.width / 2 +
//                       (horizontal ? 1 : -1) * cornerRadius,
//                   n.position.dy + controller.boxSize.height / 2,
//                 ),
//                 p2: Offset(
//                   n.position.dx + controller.boxSize.width / 2,
//                   n.position.dy + controller.boxSize.height / 2,
//                 ),
//                 canvas: canvas);
//           }
//         }
//       } else {
//         for (var n in subNodes) {
//           final minx = math.min(node.position.dx, n.position.dx);
//           final maxx = math.max(node.position.dx, n.position.dx);
//           final miny = math.min(node.position.dy, n.position.dy);
//           final maxy = math.max(node.position.dy, n.position.dy);

//           final dy = (maxy - miny) / 2 + controller.boxSize.height / 2;

//           bool horizontal = maxx == node.position.dx;
//           bool vertical = maxy == node.position.dy;
//           bool clockwise = vertical ? !horizontal : horizontal;

//           drawArrow(
//             p1: Offset(
//               node.position.dx + controller.boxSize.width / 2,
//               node.position.dy + controller.boxSize.height / 2,
//             ),
//             p2: Offset(
//               node.position.dx + controller.boxSize.width / 2,
//               miny + dy + (vertical ? 1 : -1) * cornerRadius,
//             ),
//             canvas: canvas,
//           );

//           if (maxx - minx > cornerRadius * 2) {
//             linePath.arcToPoint(
//                 Offset(
//                   node.position.dx +
//                       controller.boxSize.width / 2 +
//                       (!(horizontal) ? 1 : -1) * cornerRadius,
//                   miny + dy,
//                 ),
//                 radius: Radius.circular(cornerRadius),
//                 clockwise: clockwise);

//             drawArrow(
//               p1: Offset(
//                 node.position.dx +
//                     controller.boxSize.width / 2 +
//                     (!(horizontal) ? 1 : -1) * cornerRadius,
//                 miny + dy,
//               ),
//               p2: Offset(
//                 n.position.dx +
//                     controller.boxSize.width / 2 +
//                     (horizontal ? 1 : -1) * cornerRadius,
//                 miny + dy,
//               ),
//               canvas: canvas,
//             );
//             linePath.arcToPoint(
//               Offset(
//                 n.position.dx + controller.boxSize.width / 2,
//                 miny + dy + (!vertical ? 1 : -1) * cornerRadius,
//               ),
//               radius: Radius.circular(cornerRadius),
//               clockwise: !clockwise,
//             );
//           }
//           drawArrow(
//             p1: maxx - minx <= cornerRadius * 2
//                 ? Offset(
//                     node.position.dx + controller.boxSize.width / 2,
//                     miny + dy + (vertical ? 1 : -1) * cornerRadius,
//                   )
//                 : Offset(
//                     n.position.dx + controller.boxSize.width / 2,
//                     miny + dy + (!vertical ? 1 : -1) * cornerRadius,
//                   ),
//             p2: Offset(
//               n.position.dx + controller.boxSize.width / 2,
//               n.position.dy + controller.boxSize.height / 2,
//             ),
//             canvas: canvas,
//           );

//           drawArrowsTopToBottom(n, canvas);
//         }
//       }
//     }
//   }

//   /// Draw arrows for left-to-right oriented org chart
//   void drawArrowsLeftToRight(Node<E> node, Canvas canvas) {
//     List<Node<E>> subNodes = controller.getSubNodes(node);
//     if (node.hideNodes == false) {
//       if (allLeaf(subNodes)) {
//         for (int i = 0; i < subNodes.length; i++) {
//           Node<E> n = subNodes[i];
//           final bool horizontal = n.position.dx > node.position.dx;
//           final bool vertical = n.position.dy > node.position.dy;
//           final bool c = vertical ? horizontal : !horizontal;

//           drawArrow(
//               p1: Offset(
//                 node.position.dx + controller.boxSize.width / 2,
//                 node.position.dy + controller.boxSize.height / 2,
//               ),
//               p2: Offset(
//                 n.position.dx +
//                     controller.boxSize.width / 2 +
//                     (horizontal ? -1 : 1) * cornerRadius,
//                 node.position.dy + controller.boxSize.height / 2,
//               ),
//               canvas: canvas);

//           if ((n.position.dy - node.position.dy).abs() > cornerRadius) {
//             linePath.arcToPoint(
//               Offset(
//                 n.position.dx + controller.boxSize.width / 2,
//                 node.position.dy +
//                     controller.boxSize.height / 2 +
//                     (vertical ? 1 : -1) * cornerRadius,
//               ),
//               radius: Radius.circular(cornerRadius),
//               clockwise: c,
//             );
//             drawArrow(
//                 p1: Offset(
//                   n.position.dx + controller.boxSize.width / 2,
//                   node.position.dy +
//                       controller.boxSize.height / 2 +
//                       (vertical ? 1 : -1) * cornerRadius,
//                 ),
//                 p2: Offset(
//                   n.position.dx + controller.boxSize.width / 2,
//                   n.position.dy + controller.boxSize.height / 2,
//                 ),
//                 canvas: canvas);
//           }
//         }
//       } else {
//         for (var n in subNodes) {
//           final minx = math.min(node.position.dx, n.position.dx);
//           final maxx = math.max(node.position.dx, n.position.dx);
//           final miny = math.min(node.position.dy, n.position.dy);
//           final maxy = math.max(node.position.dy, n.position.dy);

//           final dx = (maxx - minx) / 2 + controller.boxSize.width / 2;

//           bool horizontal = maxx == node.position.dx;
//           bool vertical = maxy == node.position.dy;
//           bool clockwise = horizontal ? !vertical : vertical;

//           drawArrow(
//             canvas: canvas,
//             p1: Offset(
//               node.position.dx + controller.boxSize.width / 2,
//               node.position.dy + controller.boxSize.height / 2,
//             ),
//             p2: Offset(minx + dx + (horizontal ? 1 : -1) * cornerRadius,
//                 node.position.dy + controller.boxSize.height / 2),
//           );

//           if (maxy - miny > cornerRadius * 2) {
//             linePath.arcToPoint(
//                 Offset(
//                   minx + dx,
//                   node.position.dy +
//                       controller.boxSize.height / 2 +
//                       (vertical ? -1 : 1) * cornerRadius,
//                 ),
//                 radius: Radius.circular(cornerRadius),
//                 clockwise: !clockwise);

//             drawArrow(
//               canvas: canvas,
//               p1: Offset(
//                 minx + dx,
//                 node.position.dy +
//                     controller.boxSize.height / 2 +
//                     (vertical ? -1 : 1) * cornerRadius,
//               ),
//               p2: Offset(
//                 minx + dx,
//                 n.position.dy +
//                     controller.boxSize.height / 2 +
//                     (vertical ? 1 : -1) * cornerRadius,
//               ),
//             );

//             linePath.arcToPoint(
//                 Offset(
//                   minx + dx + (!horizontal ? 1 : -1) * cornerRadius,
//                   n.position.dy + controller.boxSize.height / 2,
//                 ),
//                 radius: Radius.circular(cornerRadius),
//                 clockwise: clockwise);
//           }
//           drawArrow(
//             canvas: canvas,
//             p1: maxy - miny <= cornerRadius * 2
//                 ? Offset(minx + dx + (horizontal ? 1 : -1) * cornerRadius,
//                     node.position.dy + controller.boxSize.height / 2)
//                 : Offset(
//                     minx + dx + (!horizontal ? 1 : -1) * cornerRadius,
//                     n.position.dy + controller.boxSize.height / 2,
//                   ),
//             p2: Offset(n.position.dx + controller.boxSize.width / 2,
//                 n.position.dy + controller.boxSize.height / 2),
//           );

//           drawArrowsLeftToRight(n, canvas);
//         }
//       }
//     }
//   }
}
