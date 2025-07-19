import 'package:flutter/material.dart';
import 'package:org_chart/org_chart.dart';

/// Configuration class for organization chart settings
class ChartConfig {
  // Layout settings
  GraphOrientation orientation;
  double nodeSpacing;
  double levelSpacing;
  double cornerRadius;

  /// Number of columns to arrange leaf nodes in (nodes without children)
  /// Higher values create wider but shorter charts
  int leafColumnCount;

  // Arrow style
  GraphArrowStyle arrowStyle;
  LineEndingType lineEndingType;
  List<double> dashPattern;
  double dashThickness;

  // Interaction settings
  bool isDraggable;
  bool enableZoom;

  // Scale settings
  double minScale;
  double maxScale;

  // Animation settings
  Duration animationDuration;
  Curve animationCurve;

  // Interactive viewer settings
  bool enableRotation;
  bool constrainBounds;
  bool enableDoubleTapZoom;
  double doubleTapZoomFactor;
  bool enableKeyboardControls;
  double keyboardPanDistance;
  double keyboardZoomFactor;
  bool enableKeyRepeat;
  Duration keyRepeatInitialDelay;
  Duration keyRepeatInterval;
  bool enableCtrlScrollToScale;
  bool enableFling;
  bool enablePan;
  // Zoom on node Settings
  String? zoomOnNodeId;
  double zoomOnNodeScaleFactor;
  // Keyboard animation settings
  bool animateKeyboardTransitions;
  Curve keyboardAnimationCurve;
  Duration keyboardAnimationDuration;

  // Keyboard direction settings
  bool invertArrowKeyDirection;
  ChartConfig({
    this.orientation = GraphOrientation.topToBottom,
    this.nodeSpacing = 20.0,
    this.levelSpacing = 40.0,
    this.cornerRadius = 8.0,
    this.leafColumnCount = 4,
    GraphArrowStyle? arrowStyle,
    this.lineEndingType = LineEndingType.arrow,
    List<double>? dashPattern,
    this.dashThickness = 2.0,
    this.isDraggable = true,
    this.enableZoom = true,
    this.minScale = 0.5,
    this.maxScale = 4.0,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeInOut,
    this.enableRotation = false,
    this.constrainBounds = false,
    this.enableDoubleTapZoom = false,
    this.doubleTapZoomFactor = 2.0,
    this.enableKeyboardControls = true,
    this.keyboardPanDistance = 20.0,
    this.keyboardZoomFactor = 1.1,
    this.enableKeyRepeat = true,
    this.keyRepeatInitialDelay = const Duration(milliseconds: 500),
    this.keyRepeatInterval = const Duration(milliseconds: 50),
    this.enableCtrlScrollToScale = true,
    this.enableFling = true,
    this.enablePan = true,
    this.zoomOnNodeId,
    this.zoomOnNodeScaleFactor = 1.5,
    this.animateKeyboardTransitions = true,
    this.keyboardAnimationCurve = Curves.easeInOut,
    this.keyboardAnimationDuration = const Duration(milliseconds: 300),
    this.invertArrowKeyDirection = false,
  })  : dashPattern = dashPattern ?? [8.0, 4.0],
        arrowStyle = arrowStyle ?? const SolidGraphArrow();

  /// Get a Paint object for lines based on current settings
  Paint getLinePaint(BuildContext context) {
    return Paint()
      ..color = Theme.of(context).colorScheme.primary
      ..strokeWidth = arrowStyle is DashedGraphArrow ? dashThickness : 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
  }

  /// Update the arrow style based on current dash pattern
  void updateDashedArrowStyle() {
    if (arrowStyle is DashedGraphArrow) {
      arrowStyle = DashedGraphArrow(pattern: dashPattern);
    }
  }

  /// Helper method to determine the current dash pattern type
  String getDashPatternType() {
    if (dashPattern.length > 2) return 'complex';
    if (dashPattern[0] <= 1.0) return 'dotted';
    return 'simple';
  }
}
