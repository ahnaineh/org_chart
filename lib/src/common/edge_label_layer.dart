import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:org_chart/src/common/edge_models.dart';
import 'package:org_chart/src/common/measure_size.dart';

class EdgeLabelLayer<E> extends StatefulWidget {
  final List<EdgeInfo<E>> edges;
  final Widget? Function(EdgeInfo<E> edge) labelBuilder;
  final EdgeLabelConfig config;
  final Size graphSize;
  final EdgeStyle Function(EdgeInfo<E> edge)? edgeStyleProvider;

  const EdgeLabelLayer({
    super.key,
    required this.edges,
    required this.labelBuilder,
    required this.config,
    required this.graphSize,
    this.edgeStyleProvider,
  });

  @override
  State<EdgeLabelLayer<E>> createState() => _EdgeLabelLayerState<E>();
}

class _EdgeLabelLayerState<E> extends State<EdgeLabelLayer<E>> {
  final Map<String, Size> _sizes = {};

  @override
  Widget build(BuildContext context) {
    final List<Rect> placedRects = [];
    final List<_LabelPlacement> placements = [];

    for (final edge in widget.edges) {
      final EdgeStyle style =
          edge.baseStyle.merge(widget.edgeStyleProvider?.call(edge));
      if (style.isHidden) continue;

      final Widget? label = widget.labelBuilder(edge);
      if (label == null) continue;

      final double labelOpacity =
          (style.opacity ?? 1.0).clamp(0.0, 1.0);
      if (labelOpacity <= 0) continue;

      final Size size = _sizes[edge.id] ?? Size.zero;
      final _PathProbe probe =
          _EdgeLabelLayout.probe(edge.points, widget.config.anchor);
      final Offset? explicitPoint = edge.data['labelPoint'] as Offset?;
      Offset position = (explicitPoint ?? probe.point) + widget.config.offset;
      if (widget.config.avoidOverlaps && size != Size.zero) {
        position = _EdgeLabelLayout.resolveOverlap(
          position: position,
          size: size,
          normal: probe.normal,
          placedRects: placedRects,
          config: widget.config,
        );
      }

      if (widget.config.clampToBounds && size != Size.zero) {
        position = _EdgeLabelLayout.clampToBounds(
          position: position,
          size: size,
          bounds: widget.graphSize,
        );
      }

      if (size != Size.zero) {
        placedRects.add(_EdgeLabelLayout.rectFor(position, size,
            padding: widget.config.overlapPadding));
      }

      final double angle =
          widget.config.rotation == EdgeLabelRotation.followEdge
              ? probe.angle
              : 0.0;

      Widget child = label;
      if (labelOpacity < 1.0) {
        child = Opacity(opacity: labelOpacity, child: child);
      }

      placements.add(_LabelPlacement(
        id: edge.id,
        position: position,
        angle: angle,
        child: child,
      ));
    }

    if (placements.isEmpty) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: placements.map((placement) {
          Widget child = MeasureSize(
            onChange: (size) => _updateSize(placement.id, size),
            child: placement.child,
          );

          if (placement.angle != 0.0) {
            child = Transform.rotate(angle: placement.angle, child: child);
          }

          child = FractionalTranslation(
            translation: const Offset(-0.5, -0.5),
            child: child,
          );

          return Positioned(
            left: placement.position.dx,
            top: placement.position.dy,
            child: child,
          );
        }).toList(),
      ),
    );
  }

  void _updateSize(String id, Size size) {
    if (!mounted) return;
    if (_sizes[id] == size) return;
    setState(() {
      _sizes[id] = size;
    });
  }
}

class _LabelPlacement {
  final String id;
  final Offset position;
  final double angle;
  final Widget child;

  const _LabelPlacement({
    required this.id,
    required this.position,
    required this.angle,
    required this.child,
  });
}

class _PathProbe {
  final Offset point;
  final Offset direction;

  const _PathProbe(this.point, this.direction);

  double get angle => math.atan2(direction.dy, direction.dx);

  Offset get normal {
    if (direction.distance == 0) return const Offset(0, 1);
    return Offset(-direction.dy, direction.dx);
  }
}

class _EdgeLabelLayout {
  static _PathProbe probe(List<Offset> points, EdgeLabelAnchor anchor) {
    if (points.length < 2) {
      return _PathProbe(points.isEmpty ? Offset.zero : points.first,
          const Offset(1, 0));
    }

    final double fraction;
    switch (anchor) {
      case EdgeLabelAnchor.start:
        fraction = 0.0;
        break;
      case EdgeLabelAnchor.end:
        fraction = 1.0;
        break;
      case EdgeLabelAnchor.center:
        fraction = 0.5;
        break;
    }

    return _pointAtFraction(points, fraction);
  }

  static _PathProbe _pointAtFraction(List<Offset> points, double fraction) {
    if (points.length < 2) {
      return _PathProbe(points.isEmpty ? Offset.zero : points.first,
          const Offset(1, 0));
    }

    double totalLength = 0;
    for (int i = 0; i < points.length - 1; i++) {
      totalLength += (points[i + 1] - points[i]).distance;
    }
    if (totalLength == 0) {
      return _PathProbe(points.first, const Offset(1, 0));
    }

    double target = totalLength * fraction;
    for (int i = 0; i < points.length - 1; i++) {
      final Offset start = points[i];
      final Offset end = points[i + 1];
      final double segmentLength = (end - start).distance;
      if (segmentLength <= 0) continue;

      if (target <= segmentLength) {
        final double t = target / segmentLength;
        final Offset point = Offset(
          start.dx + (end.dx - start.dx) * t,
          start.dy + (end.dy - start.dy) * t,
        );
        final Offset direction = Offset(
          (end.dx - start.dx) / segmentLength,
          (end.dy - start.dy) / segmentLength,
        );
        return _PathProbe(point, direction);
      }

      target -= segmentLength;
    }

    final Offset fallbackDirection = points.length >= 2
        ? (points.last - points[points.length - 2])
        : const Offset(1, 0);
    final double distance = fallbackDirection.distance;
    final Offset normalized = distance == 0
        ? const Offset(1, 0)
        : Offset(
            fallbackDirection.dx / distance,
            fallbackDirection.dy / distance,
          );
    return _PathProbe(points.last, normalized);
  }

  static Rect rectFor(Offset center, Size size, {double padding = 0}) {
    return Rect.fromLTWH(
      center.dx - size.width / 2 - padding,
      center.dy - size.height / 2 - padding,
      size.width + padding * 2,
      size.height + padding * 2,
    );
  }

  static Offset resolveOverlap({
    required Offset position,
    required Size size,
    required Offset normal,
    required List<Rect> placedRects,
    required EdgeLabelConfig config,
  }) {
    if (placedRects.isEmpty) return position;

    Rect rect = rectFor(position, size, padding: config.overlapPadding);
    if (!_intersectsAny(rect, placedRects)) return position;

    final Offset unitNormal =
        normal.distance == 0 ? const Offset(0, 1) : normal / normal.distance;
    for (int step = 1; step <= config.maxShiftSteps; step++) {
      final double shift = config.shiftStep * step;
      for (final double direction in const [1, -1]) {
        final Offset candidate = position + unitNormal * shift * direction;
        final Rect candidateRect =
            rectFor(candidate, size, padding: config.overlapPadding);
        if (!_intersectsAny(candidateRect, placedRects)) {
          return candidate;
        }
      }
    }

    return position;
  }

  static Offset clampToBounds({
    required Offset position,
    required Size size,
    required Size bounds,
  }) {
    if (bounds == Size.zero) return position;
    final double minX = size.width / 2;
    final double maxX = math.max(minX, bounds.width - size.width / 2);
    final double minY = size.height / 2;
    final double maxY = math.max(minY, bounds.height - size.height / 2);

    return Offset(
      position.dx.clamp(minX, maxX).toDouble(),
      position.dy.clamp(minY, maxY).toDouble(),
    );
  }

  static bool _intersectsAny(Rect rect, List<Rect> others) {
    for (final other in others) {
      if (rect.overlaps(other)) return true;
    }
    return false;
  }
}
