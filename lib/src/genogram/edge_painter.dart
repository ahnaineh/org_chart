import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:org_chart/src/base/edge_painter_utils.dart';
import 'package:org_chart/src/genogram/genogram_enums.dart';
import 'package:org_chart/src/common/node.dart';
import 'package:org_chart/src/base/base_controller.dart';
import 'package:org_chart/src/genogram/genogram_controller.dart';
import 'package:org_chart/src/genogram/genogram_edge_config.dart';
import 'package:org_chart/src/common/edge_models.dart';
import 'package:org_chart/src/genogram/marriage_style.dart';

/// Connection points on a node
enum ConnectionPoint {
  top,
  right,
  bottom,
  left,
  center,
}

/// Relationship type in a genogram
enum RelationshipType {
  marriage,
  parent,
  child,
}

/// A highly customizable painter for genogram edges
class GenogramEdgePainter<E> extends CustomPainter {
  final GenogramController<E> controller;

  final EdgePainterUtils utils;

  /// Configuration for edge styling
  final GenogramEdgeConfig config;

  /// Edge styling callback for per-edge customization
  final EdgeStyle Function(EdgeInfo<E> edge)? edgeStyleProvider;

  /// Function to get marriage status for a relationship (defaults to married)
  final MarriageStatus Function(E person, E spouse)? marriageStatusProvider;

  /// Text direction for handling LTR/RTL layouts
  final TextDirection textDirection;

  GenogramEdgePainter({
    required this.controller,
    required Paint linePaint,
    double cornerRadius = 15,
    required GraphArrowStyle arrowStyle,
    LineEndingType lineEndingType = LineEndingType.arrow,
    this.config = const GenogramEdgeConfig(),
    this.marriageStatusProvider,
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
  void paint(Canvas canvas, Size size) {
    final edges = buildEdges(size);
    for (final edge in edges) {
      final EdgeStyle style =
          edge.baseStyle.merge(edgeStyleProvider?.call(edge));
      if (style.isHidden) continue;

      final Paint paint = style.applyTo(utils.linePaint);
      final Offset start = edge.points.first;
      final Offset end = edge.points.last;

      if (edge.type == EdgeType.genogramMarriage) {
        canvas.drawLine(start, end, paint);
        final MarriageDecorator? decorator =
            edge.data['decorator'] as MarriageDecorator?;
        if (decorator != null) {
          final double opacity =
              (style.opacity ?? 1.0).clamp(0.0, 1.0).toDouble();
          if (opacity < 1.0) {
            canvas.saveLayer(
              null,
              Paint()..color = Colors.white.withValues(alpha: opacity),
            );
            decorator.paint(canvas, start, end, strokeWidth: paint.strokeWidth);
            canvas.restore();
          } else {
            decorator.paint(canvas, start, end, strokeWidth: paint.strokeWidth);
          }
        }
      } else {
        utils.drawConnectionWithPoints(canvas, edge.points, paint: paint);
      }
    }
  }

  List<EdgeInfo<E>> buildEdges(Size size) {
    final List<Node<E>> nodes = controller.nodes;
    final List<_MarriageInfo<E>> marriages = _collectMarriages(nodes);
    final Map<String, Color> marriageColors = {};
    final Map<String, Offset> marriagePoints = {};
    final List<EdgeInfo<E>> edges = [];

    marriages.sort((a, b) => a.marriageKey.compareTo(b.marriageKey));

    for (int i = 0; i < marriages.length; i++) {
      final _MarriageInfo<E> marriage = marriages[i];
      final Color marriageColor =
          config.marriageColors[i % config.marriageColors.length];
      marriageColors[marriage.marriageKey] = marriageColor;

      final Offset husbandConn =
          _getConnectionPoint(marriage.husband, ConnectionPoint.right);
      final Offset wifeConn =
          _getConnectionPoint(marriage.wife, ConnectionPoint.left);

      final double offset = -5.0 * marriage.spouseIndex;
      final Offset husbandOffset;
      final Offset wifeOffset;

      if (controller.orientation == GraphOrientation.topToBottom) {
        husbandOffset = husbandConn.translate(0, offset);
        wifeOffset = wifeConn.translate(0, offset);
      } else {
        husbandOffset = husbandConn.translate(offset, 0);
        wifeOffset = wifeConn.translate(offset, 0);
      }

      MarriageStatus status = MarriageStatus.married;
      if (marriageStatusProvider != null) {
        status =
            marriageStatusProvider!(marriage.husband.data, marriage.wife.data);
      }

      final MarriageStyle marriageStyle = config.getMarriageStyle(status);
      final EdgeStyle baseStyle = EdgeStyle(
        color: marriageColor,
        strokeWidth: marriageStyle.lineStyle.strokeWidth,
        paintStyle: marriageStyle.lineStyle.paintStyle,
      );

      final Offset marriagePoint = _getMarriagePoint(husbandOffset, wifeOffset);
      marriagePoints[marriage.marriageKey] = marriagePoint;

      edges.add(EdgeInfo<E>(
        id: 'marriage:${marriage.marriageKey}',
        type: EdgeType.genogramMarriage,
        source: marriage.husband,
        target: marriage.wife,
        orientation: controller.orientation,
        points: [husbandOffset, wifeOffset],
        connectionType: ConnectionType.direct,
        baseStyle: baseStyle,
        data: {
          'marriageKey': marriage.marriageKey,
          'spouseIndex': marriage.spouseIndex,
          'marriageStatus': status,
          'decorator': marriageStyle.decorator,
          'labelPoint': marriagePoint,
        },
      ));
    }

    edges.addAll(_buildParentChildEdges(nodes, marriagePoints, marriageColors));
    return _applyTextDirection(edges, size.width);
  }

  List<EdgeInfo<E>> _buildParentChildEdges(
    List<Node<E>> nodes,
    Map<String, Offset> marriagePoints,
    Map<String, Color> marriageColors,
  ) {
    final List<EdgeInfo<E>> edges = [];

    for (final Node<E> child in nodes) {
      final String? fatherId = controller.fatherProvider(child.data);
      final String? motherId = controller.motherProvider(child.data);
      if (fatherId == null && motherId == null) continue;

      Node<E>? father;
      Node<E>? mother;

      if (fatherId != null) {
        father = nodes
            .where((node) => controller.idProvider(node.data) == fatherId)
            .firstOrNull;
      }

      if (motherId != null) {
        mother = nodes
            .where((node) => controller.idProvider(node.data) == motherId)
            .firstOrNull;
      }

      final Offset childConn = _getConnectionPoint(child, ConnectionPoint.top);
      final bool isMarriedFemale = controller.isFemale(child.data) &&
          controller.getSpouseList(child.data).isNotEmpty;

      if (father != null && mother != null) {
        final String marriageKey =
            '${controller.idProvider(father.data)}|${controller.idProvider(mother.data)}';

        if (marriagePoints.containsKey(marriageKey)) {
          final Offset marriagePoint = marriagePoints[marriageKey]!;
          final Color marriageColor =
              marriageColors[marriageKey] ?? Colors.grey;
          final ConnectionType connectionType = isMarriedFemale
              ? ConnectionType.twoSegment
              : ConnectionType.genogramParentChild;

          final List<Offset> points = utils.getConnectionPoints(
            type: connectionType,
            start: marriagePoint,
            end: childConn,
            startSize: _maxSize(father.size, mother.size),
            endSize: child.size,
            orientation: controller.orientation,
          );

          edges.add(EdgeInfo<E>(
            id: 'pc:$marriageKey:${controller.idProvider(child.data)}',
            type: EdgeType.genogramParentChild,
            source: father,
            target: child,
            orientation: controller.orientation,
            points: points,
            connectionType: connectionType,
            baseStyle: EdgeStyle(
              color: marriageColor,
              strokeWidth: config.childStrokeWidth,
              paintStyle: PaintingStyle.stroke,
            ),
            data: {
              'marriageKey': marriageKey,
              'father': father,
              'mother': mother,
              'isSingleParent': false,
              'isMarriedFemale': isMarriedFemale,
              'labelPoint': _lastSegmentMidpoint(points),
            },
          ));
        } else {
          edges.addAll(_buildSingleParentEdges(
              father, child, isMarriedFemale, 'father'));
          edges.addAll(_buildSingleParentEdges(
              mother, child, isMarriedFemale, 'mother'));
        }
      } else if (father != null) {
        edges.addAll(
            _buildSingleParentEdges(father, child, isMarriedFemale, 'father'));
      } else if (mother != null) {
        edges.addAll(
            _buildSingleParentEdges(mother, child, isMarriedFemale, 'mother'));
      }
    }

    return edges;
  }

  List<EdgeInfo<E>> _buildSingleParentEdges(
    Node<E> parent,
    Node<E> child,
    bool isMarriedFemale,
    String parentRole,
  ) {
    final Offset parentConn =
        _getConnectionPoint(parent, ConnectionPoint.bottom);
    final Offset childConn = _getConnectionPoint(child, ConnectionPoint.top);
    final ConnectionType connectionType =
        isMarriedFemale ? ConnectionType.twoSegment : ConnectionType.direct;

    final List<Offset> points = utils.getConnectionPoints(
      type: connectionType,
      start: parentConn,
      end: childConn,
      startSize: parent.size,
      endSize: child.size,
      orientation: controller.orientation,
    );

    return [
      EdgeInfo<E>(
        id: 'pc:${controller.idProvider(parent.data)}:${controller.idProvider(child.data)}',
        type: EdgeType.genogramParentChild,
        source: parent,
        target: child,
        orientation: controller.orientation,
        points: points,
        connectionType: connectionType,
        baseStyle: EdgeStyle(
          color: config.childSingleParentColor,
          strokeWidth: config.childSingleParentStrokeWidth,
          paintStyle: PaintingStyle.stroke,
        ),
        data: {
          'parentRole': parentRole,
          'isSingleParent': true,
          'isMarriedFemale': isMarriedFemale,
          'labelPoint': _lastSegmentMidpoint(points),
        },
      ),
    ];
  }

  List<_MarriageInfo<E>> _collectMarriages(List<Node<E>> nodes) {
    final List<_MarriageInfo<E>> marriages = [];

    for (final Node<E> person in nodes) {
      final String personId = controller.idProvider(person.data);
      final List<String>? spouses = controller.spousesProvider(person.data);
      if (spouses == null || spouses.isEmpty) continue;

      if (!controller.isMale(person.data)) continue;

      for (int i = 0; i < spouses.length; i++) {
        final String spouseId = spouses[i];
        final Node<E>? spouse = nodes
            .where((node) => controller.idProvider(node.data) == spouseId)
            .firstOrNull;
        if (spouse == null) continue;

        marriages.add(_MarriageInfo<E>(
          husband: person,
          wife: spouse,
          spouseIndex: i,
          marriageKey: '$personId|$spouseId',
        ));
      }
    }

    return marriages;
  }

  Offset _getMarriagePoint(Offset husbandOffset, Offset wifeOffset) {
    final Offset delta = husbandOffset - wifeOffset;
    final double length = delta.distance;
    if (length == 0) return wifeOffset;

    final double desiredFromWife = config.marriageAnchorDistance;
    final double maxFromWife = length / 2;
    final double fromWife =
        desiredFromWife > maxFromWife ? maxFromWife : desiredFromWife;
    final Offset direction = delta / length;
    return wifeOffset + direction * fromWife;
  }

  Offset _lastSegmentMidpoint(List<Offset> points) {
    if (points.length < 2) {
      return points.isEmpty ? Offset.zero : points.first;
    }
    final Offset a = points[points.length - 2];
    final Offset b = points.last;
    return Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
  }

  /// Get connection point on a node based on location
  Offset _getConnectionPoint(Node<E> node, ConnectionPoint point) {
    switch (point) {
      case ConnectionPoint.top:
        return node.renderPosition + Offset(node.size.width / 2, 0);
      case ConnectionPoint.right:
        return node.renderPosition +
            Offset(node.size.width, node.size.height / 2);
      case ConnectionPoint.bottom:
        return node.renderPosition +
            Offset(node.size.width / 2, node.size.height);
      case ConnectionPoint.left:
        return node.renderPosition + Offset(0, node.size.height / 2);
      case ConnectionPoint.center:
        return node.renderPosition +
            Offset(node.size.width / 2, node.size.height / 2);
    }
  }

  List<EdgeInfo<E>> _applyTextDirection(List<EdgeInfo<E>> edges, double width) {
    if (textDirection != TextDirection.rtl) return edges;
    return edges.map((edge) => _mirrorEdge(edge, width)).toList();
  }

  Size _maxSize(Size a, Size b) {
    return Size(math.max(a.width, b.width), math.max(a.height, b.height));
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

  @override
  bool shouldRepaint(covariant GenogramEdgePainter<E> oldDelegate) {
    // Only repaint if the controller, configs, or paint properties have changed
    return oldDelegate.controller != controller ||
        oldDelegate.config != config ||
        oldDelegate.marriageStatusProvider != marriageStatusProvider ||
        oldDelegate.edgeStyleProvider != edgeStyleProvider ||
        oldDelegate.utils.linePaint != utils.linePaint ||
        oldDelegate.utils.cornerRadius != utils.cornerRadius ||
        oldDelegate.utils.arrowStyle != utils.arrowStyle ||
        oldDelegate.utils.lineEndingType != utils.lineEndingType ||
        oldDelegate.textDirection != textDirection;
  }
}

class _MarriageInfo<E> {
  final Node<E> husband;
  final Node<E> wife;
  final int spouseIndex;
  final String marriageKey;

  const _MarriageInfo({
    required this.husband,
    required this.wife,
    required this.spouseIndex,
    required this.marriageKey,
  });
}
