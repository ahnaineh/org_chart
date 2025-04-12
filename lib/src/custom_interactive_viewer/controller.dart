import 'dart:ui';

import 'package:flutter/foundation.dart';

class CustomInteractiveViewerController extends ChangeNotifier {
  double scale;
  Offset offset;

  CustomInteractiveViewerController({
    this.scale = 1.0,
    this.offset = Offset.zero,
  });

  /// Programmatically center the content.
  /// [viewportSize] is the size of the container.
  /// [contentSize] is the intrinsic size of the content widget.
  void center(Size viewportSize, Size contentSize) {
    final double newOffsetX =
        (viewportSize.width - contentSize.width * scale) / 2;
    final double newOffsetY =
        (viewportSize.height - contentSize.height * scale) / 2;
    offset = Offset(newOffsetX, newOffsetY);
    notifyListeners();
  }

  /// Update the controller state.
  /// Calling this will notify the viewer to rebuild with the new matrix.
  void update({double? newScale, Offset? newOffset}) {
    if (newScale != null) scale = newScale;
    if (newOffset != null) offset = newOffset;
    notifyListeners();
  }
}
