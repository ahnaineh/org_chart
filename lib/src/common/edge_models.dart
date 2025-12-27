import 'package:flutter/material.dart';
import 'package:org_chart/src/base/base_controller.dart';
import 'package:org_chart/src/base/edge_painter_utils.dart';
import 'package:org_chart/src/common/node.dart';

/// Supported edge types across chart variants.
enum EdgeType {
  orgChartParentChild,
  genogramMarriage,
  genogramParentChild,
}

/// Edge metadata shared with painters and label builders.
class EdgeInfo<E> {
  final String id;
  final EdgeType type;
  final Node<E> source;
  final Node<E> target;
  final GraphOrientation orientation;
  final List<Offset> points;
  final ConnectionType? connectionType;
  final EdgeStyle baseStyle;
  final Map<String, Object?> data;

  const EdgeInfo({
    required this.id,
    required this.type,
    required this.source,
    required this.target,
    required this.orientation,
    required this.points,
    required this.baseStyle,
    this.connectionType,
    this.data = const {},
  });

  EdgeInfo<E> copyWith({
    String? id,
    EdgeType? type,
    Node<E>? source,
    Node<E>? target,
    GraphOrientation? orientation,
    List<Offset>? points,
    ConnectionType? connectionType,
    EdgeStyle? baseStyle,
    Map<String, Object?>? data,
  }) {
    return EdgeInfo<E>(
      id: id ?? this.id,
      type: type ?? this.type,
      source: source ?? this.source,
      target: target ?? this.target,
      orientation: orientation ?? this.orientation,
      points: points ?? this.points,
      connectionType: connectionType ?? this.connectionType,
      baseStyle: baseStyle ?? this.baseStyle,
      data: data ?? this.data,
    );
  }
}

/// Styling overrides for edges, applied on top of painter defaults.
class EdgeStyle {
  final Color? color;
  final double? strokeWidth;
  final double? opacity;
  final PaintingStyle? paintStyle;
  final StrokeCap? strokeCap;
  final bool hidden;

  const EdgeStyle({
    this.color,
    this.strokeWidth,
    this.opacity,
    this.paintStyle,
    this.strokeCap,
    this.hidden = false,
  });

  bool get isHidden => hidden || (opacity != null && opacity! <= 0);

  EdgeStyle merge(EdgeStyle? other) {
    if (other == null) return this;
    return EdgeStyle(
      color: other.color ?? color,
      strokeWidth: other.strokeWidth ?? strokeWidth,
      opacity: other.opacity ?? opacity,
      paintStyle: other.paintStyle ?? paintStyle,
      strokeCap: other.strokeCap ?? strokeCap,
      hidden: other.hidden || hidden,
    );
  }

  Paint applyTo(Paint basePaint) {
    final Color baseColor = color ?? basePaint.color;
    final double opacityValue =
        (opacity ?? 1.0).clamp(0.0, 1.0).toDouble();
    final double mergedOpacity = (baseColor.opacity * opacityValue)
        .clamp(0.0, 1.0)
        .toDouble();

    return Paint()
      ..blendMode = basePaint.blendMode
      ..isAntiAlias = basePaint.isAntiAlias
      ..strokeJoin = basePaint.strokeJoin
      ..strokeMiterLimit = basePaint.strokeMiterLimit
      ..color = baseColor.withOpacity(mergedOpacity)
      ..strokeWidth = strokeWidth ?? basePaint.strokeWidth
      ..style = paintStyle ?? basePaint.style
      ..strokeCap = strokeCap ?? basePaint.strokeCap;
  }
}

/// Anchor position for edge labels along an edge path.
enum EdgeLabelAnchor { start, center, end }

/// Rotation behavior for edge labels.
enum EdgeLabelRotation { none, followEdge }

/// Configuration for edge label placement.
class EdgeLabelConfig {
  final EdgeLabelAnchor anchor;
  final EdgeLabelRotation rotation;
  final Offset offset;
  final bool clampToBounds;
  final bool avoidOverlaps;
  final double overlapPadding;
  final int maxShiftSteps;
  final double shiftStep;

  const EdgeLabelConfig({
    this.anchor = EdgeLabelAnchor.center,
    this.rotation = EdgeLabelRotation.none,
    this.offset = Offset.zero,
    this.clampToBounds = true,
    this.avoidOverlaps = false,
    this.overlapPadding = 6.0,
    this.maxShiftSteps = 4,
    this.shiftStep = 12.0,
  });

  EdgeLabelConfig copyWith({
    EdgeLabelAnchor? anchor,
    EdgeLabelRotation? rotation,
    Offset? offset,
    bool? clampToBounds,
    bool? avoidOverlaps,
    double? overlapPadding,
    int? maxShiftSteps,
    double? shiftStep,
  }) {
    return EdgeLabelConfig(
      anchor: anchor ?? this.anchor,
      rotation: rotation ?? this.rotation,
      offset: offset ?? this.offset,
      clampToBounds: clampToBounds ?? this.clampToBounds,
      avoidOverlaps: avoidOverlaps ?? this.avoidOverlaps,
      overlapPadding: overlapPadding ?? this.overlapPadding,
      maxShiftSteps: maxShiftSteps ?? this.maxShiftSteps,
      shiftStep: shiftStep ?? this.shiftStep,
    );
  }
}
