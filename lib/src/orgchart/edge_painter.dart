import 'package:flutter/material.dart';
import 'package:org_chart/src/base/base_controller.dart';

import 'package:org_chart/src/base/edge_painter_utils.dart';
import 'package:org_chart/src/common/edge_models.dart';
import 'package:org_chart/src/common/node.dart';
import 'package:org_chart/src/orgchart/org_chart_controller.dart';

/// Edge painter specific to organizational charts
// extends BaseEdgePainter<E>
class OrgChartEdgePainter<E> extends CustomPainter {
  /// The org chart controller
  final OrgChartController<E> controller;
  final EdgePainterUtils utils;
  final EdgeStyle Function(EdgeInfo<E> edge)? edgeStyleProvider;
  final TextDirection textDirection;

  OrgChartEdgePainter({
    required this.controller,
    required Paint linePaint,
    double cornerRadius = 15,
    required GraphArrowStyle arrowStyle,
    LineEndingType lineEndingType = LineEndingType.arrow,
    this.edgeStyleProvider,
    this.textDirection = TextDirection.ltr,
    super.repaint,
  })  : utils = EdgePainterUtils(
          linePaint: linePaint,
          cornerRadius: cornerRadius,
          arrowStyle: arrowStyle,
          lineEndingType: lineEndingType,
        );

  @override
  bool shouldRepaint(covariant OrgChartEdgePainter<E> oldDelegate) {
    // Only repaint if the controller or paint properties have changed
    return oldDelegate.controller != controller ||
        oldDelegate.edgeStyleProvider != edgeStyleProvider ||
        oldDelegate.utils.linePaint != utils.linePaint ||
        oldDelegate.utils.cornerRadius != utils.cornerRadius ||
        oldDelegate.utils.arrowStyle != utils.arrowStyle ||
        oldDelegate.utils.lineEndingType != utils.lineEndingType ||
        oldDelegate.textDirection != textDirection;
  }

  /// Draw arrows for all root nodes
  @override
  void paint(Canvas canvas, Size size) {
    final edges = buildEdges(size);
    for (final edge in edges) {
      final EdgeStyle style =
          edge.baseStyle.merge(edgeStyleProvider?.call(edge));
      if (style.isHidden) continue;

      final Paint paint = style.applyTo(utils.linePaint);
      utils.drawConnectionWithPoints(canvas, edge.points, paint: paint);
    }
  }

  List<EdgeInfo<E>> buildEdges(Size size) {
    final List<EdgeInfo<E>> edges = [];
    for (final node in controller.roots) {
      _collectEdges(node, edges);
    }
    return _applyTextDirection(edges, size.width);
  }

  void _collectEdges(Node<E> node, List<EdgeInfo<E>> edges) {
    final List<Node<E>> subNodes = controller.getSubNodes(node);

    if (node.hideNodes == false && subNodes.isNotEmpty) {
      final bool allChildrenAreLeaves =
          subNodes.every((child) => isLeafNode(child));

      for (int i = 0; i < subNodes.length; i++) {
        final Node<E> subNode = subNodes[i];
        Offset start;
        Offset end;

        if (controller.orientation == GraphOrientation.leftToRight) {
          start = getNodeCenter(node) + Offset(node.size.width / 2, 0);

          if (allChildrenAreLeaves) {
            end = getNodeCenter(subNode);
          } else {
            end = getNodeCenter(subNode) -
                Offset(subNode.size.width / 2, 0);
          }
        } else {
          start = getNodeCenter(node) + Offset(0, node.size.height / 2);

          if (allChildrenAreLeaves) {
            end = getNodeCenter(subNode);
          } else {
            end = getNodeCenter(subNode) -
                Offset(0, subNode.size.height / 2);
          }
        }

        final ConnectionType connectionType = allChildrenAreLeaves
            ? ConnectionType.simpleLeafNode
            : ConnectionType.adaptive;
        final ConnectionType resolvedType = utils.resolveConnectionType(
          type: connectionType,
          start: start,
          end: end,
          orientation: controller.orientation,
        );

        final List<Offset> points = utils.getConnectionPoints(
          type: resolvedType,
          start: start,
          end: end,
          startSize: node.size,
          endSize: subNode.size,
          orientation: controller.orientation,
        );

        edges.add(EdgeInfo<E>(
          id: 'org:${controller.idProvider(node.data)}:${controller.idProvider(subNode.data)}',
          type: EdgeType.orgChartParentChild,
          source: node,
          target: subNode,
          orientation: controller.orientation,
          points: points,
          connectionType: resolvedType,
          baseStyle: const EdgeStyle(),
          data: {
            'allChildrenAreLeaves': allChildrenAreLeaves,
            'labelPoint': allChildrenAreLeaves
                ? _leafLabelPoint(points, subNode)
                : _lastSegmentMidpoint(points),
          },
        ));
      }

      for (final subNode in subNodes) {
        if (!isLeafNode(subNode)) {
          _collectEdges(subNode, edges);
        }
      }
    }
  }

  /// Get the center position of a node
  Offset getNodeCenter(Node<E> node) {
    return node.renderPosition +
        Offset(node.size.width / 2, node.size.height / 2);
  }

  /// Check if a node is a leaf node (no visible children)
  bool isLeafNode(Node<E> node) {
    return node.hideNodes || controller.getSubNodes(node).isEmpty;
  }

  Offset _lastSegmentMidpoint(List<Offset> points) {
    if (points.length < 2) {
      return points.isEmpty ? Offset.zero : points.first;
    }
    final Offset a = points[points.length - 2];
    final Offset b = points.last;
    return Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
  }

  Offset _leafLabelPoint(List<Offset> points, Node<E> child) {
    if (points.length < 2) {
      return points.isEmpty ? Offset.zero : points.first;
    }

    int longestIndex = 0;
    double longestLength = 0;
    for (int i = 0; i < points.length - 1; i++) {
      final double length = (points[i + 1] - points[i]).distance;
      if (length > longestLength) {
        longestLength = length;
        longestIndex = i;
      }
    }

    final Offset a = points[longestIndex];
    final Offset b = points[longestIndex + 1];
    final Offset segment = b - a;
    final double length = segment.distance;
    if (length == 0) {
      return a;
    }

    final Offset childCenter = getNodeCenter(child);
    final double distA = (childCenter - a).distance;
    final double distB = (childCenter - b).distance;
    final Offset near = distA <= distB ? a : b;
    final Offset far = distA <= distB ? b : a;

    final bool isMostlyHorizontal = segment.dx.abs() >= segment.dy.abs();
    final double nodeLength =
        isMostlyHorizontal ? child.size.width : child.size.height;
    final double desired = nodeLength * 0.5;

    if (desired >= length) {
      return Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    }

    final Offset direction = (far - near) / length;
    return near + direction * desired;
  }

  List<EdgeInfo<E>> _applyTextDirection(List<EdgeInfo<E>> edges, double width) {
    if (textDirection != TextDirection.rtl) return edges;
    return edges.map((edge) => _mirrorEdge(edge, width)).toList();
  }

  EdgeInfo<E> _mirrorEdge(EdgeInfo<E> edge, double width) {
    final List<Offset> points = utils.resolveDirectionalPoints(
      points: edge.points,
      width: width,
      textDirection: textDirection,
    );

    if (!edge.data.containsKey('labelPoint')) {
      return edge.copyWith(points: points);
    }

    final Object? labelPoint = edge.data['labelPoint'];
    if (labelPoint is! Offset) {
      return edge.copyWith(points: points);
    }

    final Map<String, Object?> data = Map<String, Object?>.from(edge.data);
    data['labelPoint'] = utils.resolveDirectionalOffset(
      offset: labelPoint,
      width: width,
      textDirection: textDirection,
    );

    return edge.copyWith(points: points, data: data);
  }
}
