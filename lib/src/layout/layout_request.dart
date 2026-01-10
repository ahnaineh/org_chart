import 'dart:ui';

import 'layout_graph.dart';
import 'layout_orientation.dart';

/// Input to a single layout run.
///
/// This is designed to be engine-agnostic and testable without Flutter widgets.
class LayoutRequest<G extends LayoutGraph> {
  final G graph;
  final LayoutOrientation orientation;

  /// Primary spacing between sibling nodes.
  final double spacing;

  /// Secondary spacing between rows/levels.
  final double runSpacing;

  /// Optional root id to layout. `null` indicates a full-graph layout.
  final String? subtreeId;

  /// Whether an engine is allowed to place nodes in overlapping regions.
  final bool allowOverlaps;

  /// Whether an engine should attempt an incremental update using
  /// [previousPositions] as a hint.
  final bool enableIncremental;

  /// Prior positions (top-left) for incremental layout, if supported.
  final Map<String, Offset>? previousPositions;

  LayoutRequest({
    required this.graph,
    this.orientation = LayoutOrientation.topToBottom,
    this.spacing = 20,
    this.runSpacing = 50,
    this.subtreeId,
    this.allowOverlaps = false,
    this.enableIncremental = false,
    this.previousPositions,
  }) : assert(spacing >= 0, 'spacing must be >= 0'),
       assert(runSpacing >= 0, 'runSpacing must be >= 0');

  LayoutRequest<G> copyWith({
    G? graph,
    LayoutOrientation? orientation,
    double? spacing,
    double? runSpacing,
    String? subtreeId,
    bool? allowOverlaps,
    bool? enableIncremental,
    Map<String, Offset>? previousPositions,
  }) {
    return LayoutRequest<G>(
      graph: graph ?? this.graph,
      orientation: orientation ?? this.orientation,
      spacing: spacing ?? this.spacing,
      runSpacing: runSpacing ?? this.runSpacing,
      subtreeId: subtreeId ?? this.subtreeId,
      allowOverlaps: allowOverlaps ?? this.allowOverlaps,
      enableIncremental: enableIncremental ?? this.enableIncremental,
      previousPositions: previousPositions ?? this.previousPositions,
    );
  }
}
