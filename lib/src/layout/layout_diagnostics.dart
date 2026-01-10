import 'dart:ui';

/// Optional engine diagnostics for debugging and profiling.
class LayoutDiagnostics {
  final String? engineLabel;
  final Duration? elapsed;

  /// Bounds of the requested subtree, if [LayoutRequest.subtreeId] was used.
  final Rect? subtreeBounds;

  /// Additional engine-specific values.
  final Map<String, Object?> extras;

  const LayoutDiagnostics({
    this.engineLabel,
    this.elapsed,
    this.subtreeBounds,
    this.extras = const {},
  });
}
