import 'dart:ui';

import 'layout_diagnostics.dart';

/// Output from a layout run.
class LayoutResult {
  /// Top-left positions per node id.
  final Map<String, Offset> positions;

  /// Tight bounds around all positioned nodes (in the same coordinate space).
  final Rect bounds;

  /// Convenience size for the rendered content.
  final Size contentSize;

  final LayoutDiagnostics? diagnostics;

  LayoutResult({
    required this.positions,
    required this.bounds,
    this.diagnostics,
  }) : contentSize = bounds.size;
}
