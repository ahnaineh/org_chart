/// Constants for base graph functionality
class BaseGraphConstants {
  // Prevent instantiation
  BaseGraphConstants._();

  // ===== Performance and Rendering =====

  /// Default pixel ratio for image exports
  static const double defaultExportPixelRatio = 3.0;

  /// Debounce delay for drag operations (60fps)
  static const Duration dragDebounceDelay = Duration(milliseconds: 16);

  // ===== Interactive Viewer Defaults =====

  /// Default delay before keyboard key repeat starts
  static const Duration defaultKeyRepeatInitialDelay =
      Duration(milliseconds: 500);

  /// Default interval between keyboard key repeats
  static const Duration defaultKeyRepeatInterval = Duration(milliseconds: 50);

  // ===== Edge Painter Configuration =====

  /// Fixed distance multiplier for edge routing connections
  static const double fixedDistanceMultiplier = 0.4;

  /// Default stroke width for edge lines
  static const double defaultStrokeWidth = 2.0;
}
