import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

class CustomInteractiveViewerController extends ChangeNotifier {
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  double _rotation = 0.0; // New property for rotation
  AnimationController? _animationController;
  Animation<double>? _scaleAnimation;
  Animation<Offset>? _offsetAnimation;
  Animation<double>? _rotationAnimation; // New animation for rotation
  TickerProvider? _vsync;

  // Default values to reset to
  final double _initialScale;
  final Offset _initialOffset;
  final double _initialRotation;

  // New properties for events and constraints
  bool _isPanning = false;
  bool _isScaling = false;
  bool _isAnimating = false;

  // Getters for current state
  double get scale => _scale;
  Offset get offset => _offset;
  double get rotation => _rotation;
  bool get isPanning => _isPanning;
  bool get isScaling => _isScaling;
  bool get isAnimating => _isAnimating;

  CustomInteractiveViewerController({
    TickerProvider? vsync,
    double initialScale = 1.0,
    Offset initialOffset = Offset.zero,
    double initialRotation = 0.0,
  })  : _vsync = vsync,
        _initialScale = initialScale,
        _initialOffset = initialOffset,
        _initialRotation = initialRotation,
        _scale = initialScale,
        _offset = initialOffset,
        _rotation = initialRotation;

  /// Sets or updates the ticker provider.
  set vsync(TickerProvider? value) {
    _vsync = value;
  }

  /// Updates the transformation state of the viewer
  void update({double? newScale, Offset? newOffset, double? newRotation}) {
    bool changed = false;

    if (newScale != null && newScale != _scale) {
      _scale = newScale;
      changed = true;
    }

    if (newOffset != null && newOffset != _offset) {
      _offset = newOffset;
      changed = true;
    }

    if (newRotation != null && newRotation != _rotation) {
      _rotation = newRotation;
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }

  /// Gets the current transformation matrix
  Matrix4 get transformationMatrix {
    return Matrix4.identity()
      ..translate(_offset.dx, _offset.dy)
      ..scale(_scale)
      ..rotateZ(_rotation);
  }

  /// Zoom in by the given factor
  Future<void> zoomIn({
    double factor = 1.2,
    Offset? focalPoint,
    bool animate = true,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) async {
    final targetScale = _scale * factor;

    if (focalPoint != null) {
      // Keep the focal point in the same position on screen during zoom
      final Offset beforeScaleOffset = (focalPoint - _offset) / _scale;
      final Offset afterScaleOffset = (focalPoint - _offset) / targetScale;
      final Offset offsetAdjustment =
          (afterScaleOffset - beforeScaleOffset) * targetScale;

      await animateTo(
        targetScale: targetScale,
        targetOffset: _offset - offsetAdjustment,
        duration: duration,
        curve: curve,
        animate: animate,
      );
    } else {
      await animateTo(
        targetScale: targetScale,
        duration: duration,
        curve: curve,
        animate: animate,
      );
    }
  }

  /// Zoom out by the given factor
  Future<void> zoomOut({
    double factor = 1.2,
    Offset? focalPoint,
    bool animate = true,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) async {
    final targetScale = _scale / factor;

    if (focalPoint != null) {
      // Keep the focal point in the same position on screen during zoom
      final Offset beforeScaleOffset = (focalPoint - _offset) / _scale;
      final Offset afterScaleOffset = (focalPoint - _offset) / targetScale;
      final Offset offsetAdjustment =
          (afterScaleOffset - beforeScaleOffset) * targetScale;

      await animateTo(
        targetScale: targetScale,
        targetOffset: _offset - offsetAdjustment,
        duration: duration,
        curve: curve,
        animate: animate,
      );
    } else {
      await animateTo(
        targetScale: targetScale,
        duration: duration,
        curve: curve,
        animate: animate,
      );
    }
  }

  /// Pan the view by the given delta
  Future<void> panBy(
    Offset delta, {
    bool animate = true,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) async {
    final targetOffset = _offset + delta;

    if (animate) {
      await animateTo(
        targetOffset: targetOffset,
        duration: duration,
        curve: curve,
      );
    } else {
      update(newOffset: targetOffset);
    }
  }

  /// Convert a point from screen coordinates to content coordinates
  Offset screenToContentPoint(Offset screenPoint) {
    // The inverse of our transformation
    final Matrix4 inverseTransform = Matrix4.identity()
      ..rotateZ(-_rotation)
      ..scale(1 / _scale)
      ..translate(-_offset.dx, -_offset.dy);

    final Vector3 contentPoint =
        inverseTransform.transform3(Vector3(screenPoint.dx, screenPoint.dy, 0));
    return Offset(contentPoint.x, contentPoint.y);
  }

  /// Convert a point from content coordinates to screen coordinates
  Offset contentToScreenPoint(Offset contentPoint) {
    final Matrix4 transform = Matrix4.identity()
      ..translate(_offset.dx, _offset.dy)
      ..scale(_scale)
      ..rotateZ(_rotation);

    final Vector3 screenPoint =
        transform.transform3(Vector3(contentPoint.dx, contentPoint.dy, 0));
    return Offset(screenPoint.x, screenPoint.y);
  }

  /// Fit the content to the screen size
  Future<void> fitToScreen(
    Size contentSize,
    Size viewportSize, {
    double padding = 20.0,
    bool animate = true,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) async {
    // Calculate the scale needed to fit the content in the viewport with padding
    final double horizontalScale =
        (viewportSize.width - 2 * padding) / contentSize.width;
    final double verticalScale =
        (viewportSize.height - 2 * padding) / contentSize.height;
    final double targetScale =
        horizontalScale < verticalScale ? horizontalScale : verticalScale;

    // Calculate the offset to center the content
    final Offset targetOffset = Offset(
      (viewportSize.width - contentSize.width * targetScale) / 2,
      (viewportSize.height - contentSize.height * targetScale) / 2,
    );

    if (animate) {
      await animateTo(
        targetScale: targetScale,
        targetOffset: targetOffset,
        duration: duration,
        curve: curve,
      );
    } else {
      update(newScale: targetScale, newOffset: targetOffset);
    }
  }

  /// Resets the view to initial values
  Future<void> reset({
    bool animate = true,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) async {
    if (animate) {
      await animateTo(
        targetScale: _initialScale,
        targetOffset: _initialOffset,
        targetRotation: _initialRotation,
        duration: duration,
        curve: curve,
      );
    } else {
      update(
        newScale: _initialScale,
        newOffset: _initialOffset,
        newRotation: _initialRotation,
      );
    }
  }

  /// Animates from the current state to the provided target values.
  Future<void> animateTo({
    double? targetScale,
    Offset? targetOffset,
    double? targetRotation,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    bool animate = true,
  }) async {
    if (!animate) {
      update(
        newScale: targetScale,
        newOffset: targetOffset,
        newRotation: targetRotation,
      );
      return;
    }

    if (_vsync == null) {
      throw StateError(
          'Setting vsync is required to be able to animate animations');
    }

    _isAnimating = true;
    notifyListeners();

    // Dispose any previous animation controller.
    _animationController?.dispose();
    _animationController =
        AnimationController(vsync: _vsync!, duration: duration);

    // Create animations only for the values that are provided
    if (targetScale != null) {
      _scaleAnimation = Tween<double>(
        begin: _scale,
        end: targetScale,
      ).animate(CurvedAnimation(
        parent: _animationController!,
        curve: curve,
      ));
    }

    if (targetOffset != null) {
      _offsetAnimation = Tween<Offset>(
        begin: _offset,
        end: targetOffset,
      ).animate(CurvedAnimation(
        parent: _animationController!,
        curve: curve,
      ));
    }

    if (targetRotation != null) {
      _rotationAnimation = Tween<double>(
        begin: _rotation,
        end: targetRotation,
      ).animate(CurvedAnimation(
        parent: _animationController!,
        curve: curve,
      ));
    }

    _animationController!.addListener(() {
      update(
        newScale: _scaleAnimation?.value,
        newOffset: _offsetAnimation?.value,
        newRotation: _rotationAnimation?.value,
      );
    });

    await _animationController!.forward();
    _animationController!.dispose();
    _animationController = null;

    _isAnimating = false;
    notifyListeners();
  }

  /// Zooms to a specific region of the content
  Future<void> zoomToRegion(
    Rect region,
    Size viewportSize, {
    bool animate = true,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    double padding = 20.0,
  }) async {
    // Calculate the scale needed to fit the region in the viewport with padding
    final double horizontalScale =
        (viewportSize.width - 2 * padding) / region.width;
    final double verticalScale =
        (viewportSize.height - 2 * padding) / region.height;
    final double targetScale =
        horizontalScale < verticalScale ? horizontalScale : verticalScale;

    // Calculate the offset to center the region
    final double centerX = region.left + region.width / 2;
    final double centerY = region.top + region.height / 2;
    final Offset targetOffset = Offset(
      viewportSize.width / 2 - centerX * targetScale,
      viewportSize.height / 2 - centerY * targetScale,
    );

    if (animate) {
      await animateTo(
        targetScale: targetScale,
        targetOffset: targetOffset,
        duration: duration,
        curve: curve,
      );
    } else {
      update(newScale: targetScale, newOffset: targetOffset);
    }
  }

  /// Ensures content stays within bounds
  void constrainToBounds(Size contentSize, Size viewportSize) {
    double minX, maxX, minY, maxY;

    if (contentSize.width * _scale <= viewportSize.width) {
      // If content is smaller than viewport, center it horizontally
      minX = maxX = (viewportSize.width - contentSize.width * _scale) / 2;
    } else {
      // Otherwise restrict panning to keep content filling the viewport
      minX = viewportSize.width - contentSize.width * _scale;
      maxX = 0;
    }

    if (contentSize.height * _scale <= viewportSize.height) {
      // If content is smaller than viewport, center it vertically
      minY = maxY = (viewportSize.height - contentSize.height * _scale) / 2;
    } else {
      // Otherwise restrict panning to keep content filling the viewport
      minY = viewportSize.height - contentSize.height * _scale;
      maxY = 0;
    }

    final double newX = _offset.dx.clamp(minX, maxX);
    final double newY = _offset.dy.clamp(minY, maxY);

    if (newX != _offset.dx || newY != _offset.dy) {
      update(newOffset: Offset(newX, newY));
    }
  }

  /// Sets panning state - for internal use
  void setPanning(bool value) {
    if (_isPanning != value) {
      _isPanning = value;
      notifyListeners();
    }
  }

  /// Sets scaling state - for internal use
  void setScaling(bool value) {
    if (_isScaling != value) {
      _isScaling = value;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  /// Centers the content within the viewport.
  Future<void> center(
    Size? contentSize,
    Size viewportSize, {
    bool animate = true,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) async {
    if (contentSize == null) return;

    // Calculate target offset so the content is centered.
    final Offset targetOffset = Offset(
      (viewportSize.width - contentSize.width * _scale) / 2,
      (viewportSize.height - contentSize.height * _scale) / 2,
    );

    if (animate) {
      await animateTo(
        targetScale: _scale,
        targetOffset: targetOffset,
        duration: duration,
        curve: curve,
      );
    } else {
      update(newOffset: targetOffset);
    }
  }
}
