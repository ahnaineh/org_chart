import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:org_chart/src/custom_interactive_viewer/controller.dart';

class CustomInteractiveViewer extends StatefulWidget {
  final Widget child;
  final CustomInteractiveViewerController controller;
  final Size? contentSize;

  // Added properties to match original InteractiveViewer
  final double minScale;
  final double maxScale;

  // New property for Ctrl+Scroll scaling
  final bool enableCtrlScrollToScale;

  // New properties
  final bool enableRotation;
  final bool constrainBounds;
  final bool enableDoubleTapZoom;
  final double doubleTapZoomFactor;
  final bool enableKeyboardControls;
  final double keyboardPanDistance;
  final double keyboardZoomFactor;

  // Key repeat properties
  final bool enableKeyRepeat;
  final Duration keyRepeatInitialDelay;
  final Duration keyRepeatInterval;

  const CustomInteractiveViewer({
    super.key,
    required this.child,
    required this.controller,
    this.contentSize,
    this.minScale = 0.5,
    this.maxScale = 4,
    this.enableRotation = false,
    this.constrainBounds = false,

    /// Experimental! turning this on will cause a delay in any gesture detector in the child
    this.enableDoubleTapZoom = false,
    this.doubleTapZoomFactor = 2.0,
    this.enableKeyboardControls = true,
    this.keyboardPanDistance = 20.0,
    this.keyboardZoomFactor = 1.1,
    this.enableKeyRepeat = true,
    this.keyRepeatInitialDelay = const Duration(milliseconds: 500),
    this.keyRepeatInterval = const Duration(milliseconds: 50),
    this.enableCtrlScrollToScale = true,
  });

  @override
  CustomInteractiveViewerState createState() => CustomInteractiveViewerState();
}

class CustomInteractiveViewerState extends State<CustomInteractiveViewer>
    with TickerProviderStateMixin {
  Offset _lastFocalPoint = Offset.zero;
  double _lastScale = 1.0;
  double _lastRotation = 0.0;
  final GlobalKey _viewportKey = GlobalKey();
  final FocusNode _focusNode = FocusNode();
  Offset? _doubleTapPosition;

  // Key repeat related fields
  final Set<LogicalKeyboardKey> _pressedKeys = {};
  Timer? _keyRepeatTimer;
  Timer? _keyRepeatInitialDelayTimer;

  // Track ctrl key state
  bool _isCtrlPressed = false;

  @override
  void initState() {
    super.initState();
    widget.controller.vsync = this;
    widget.controller.addListener(_onControllerUpdate);

    // Add listener for control key state
    HardwareKeyboard.instance.addHandler(_handleHardwareKeyChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.contentSize != null) {
        centerContent();
      }
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    _focusNode.dispose();
    _keyRepeatTimer?.cancel();
    _keyRepeatInitialDelayTimer?.cancel();

    // Remove key listener
    HardwareKeyboard.instance.removeHandler(_handleHardwareKeyChange);

    super.dispose();
  }

  // Handle hardware key changes to track ctrl key state
  bool _handleHardwareKeyChange(KeyEvent event) {
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.controlLeft ||
            event.logicalKey == LogicalKeyboardKey.controlRight)) {
      setState(() {
        _isCtrlPressed = true;
      });
    } else if (event is KeyUpEvent &&
        (event.logicalKey == LogicalKeyboardKey.controlLeft ||
            event.logicalKey == LogicalKeyboardKey.controlRight)) {
      setState(() {
        _isCtrlPressed = false;
      });
    }
    return false; // Return false to allow other handlers to process this event
  }

  void _onControllerUpdate() => setState(() {});

  Future<void> centerContent({
    bool animate = true,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) async {
    if (widget.contentSize == null) return;
    final RenderBox? box =
        _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final Size viewportSize = box.size;

    await widget.controller.center(
      widget.contentSize,
      viewportSize,
      animate: animate,
      duration: duration,
      curve: curve,
    );
  }

  // Process key actions for currently pressed keys
  void _processKeyActions() {
    if (!widget.enableKeyboardControls || _pressedKeys.isEmpty) return;

    double? newScale;
    Offset? newOffset;
    bool actionPerformed = false;

    // Process zoom keys
    if (_pressedKeys.contains(LogicalKeyboardKey.minus) ||
        _pressedKeys.contains(LogicalKeyboardKey.numpadSubtract)) {
      newScale = (widget.controller.scale / widget.keyboardZoomFactor)
          .clamp(widget.minScale, widget.maxScale);
      actionPerformed = true;
    } else if ((_pressedKeys.contains(LogicalKeyboardKey.equal) &&
            HardwareKeyboard.instance.isShiftPressed) ||
        _pressedKeys.contains(LogicalKeyboardKey.numpadAdd)) {
      newScale = (widget.controller.scale * widget.keyboardZoomFactor)
          .clamp(widget.minScale, widget.maxScale);
      actionPerformed = true;
    }

    // Process arrow keys for panning
    final Offset panDelta = _calculatePanDeltaFromKeys();
    if (panDelta != Offset.zero) {
      newOffset = widget.controller.offset + panDelta;
      actionPerformed = true;
    }

    // Apply actions if needed
    if (actionPerformed) {
      widget.controller.update(
        newScale: newScale,
        newOffset: newOffset,
      );

      if (widget.constrainBounds && widget.contentSize != null) {
        final RenderBox? box =
            _viewportKey.currentContext?.findRenderObject() as RenderBox?;
        if (box != null) {
          widget.controller.constrainToBounds(widget.contentSize!, box.size);
        }
      }
    }
  }

  // Calculate pan delta from currently pressed keys
  Offset _calculatePanDeltaFromKeys() {
    double dx = 0, dy = 0;

    if (_pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      dx -= widget.keyboardPanDistance;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      dx += widget.keyboardPanDistance;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      dy -= widget.keyboardPanDistance;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      dy += widget.keyboardPanDistance;
    }

    return Offset(dx, dy);
  }

  // Setup key repeat timer when a key is pressed
  void _setupKeyRepeatTimer() {
    _keyRepeatTimer?.cancel();
    _keyRepeatInitialDelayTimer?.cancel();

    // Apply action immediately for the first press
    _processKeyActions();

    if (!widget.enableKeyRepeat) return;

    // Set initial delay before rapid repeat starts
    _keyRepeatInitialDelayTimer = Timer(widget.keyRepeatInitialDelay, () {
      // Start continuous repeat timer after initial delay
      _keyRepeatTimer = Timer.periodic(widget.keyRepeatInterval, (_) {
        _processKeyActions();
      });
    });
  }

  // Handle keyboard input with key repeat
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!widget.enableKeyboardControls) {
      return KeyEventResult.ignored;
    }

    // Handle key down events
    if (event is KeyDownEvent) {
      final key = event.logicalKey;

      // Track the key press
      if (_isHandledKey(key)) {
        if (_pressedKeys.add(key)) {
          // Returns true if key was added (not already in set)
          _setupKeyRepeatTimer();
        }
        return KeyEventResult.handled;
      }

      // Handle one-time actions (like Home key)
      if (key == LogicalKeyboardKey.home) {
        widget.controller.reset();
        return KeyEventResult.handled;
      }
    }
    // Handle key up events
    else if (event is KeyUpEvent) {
      final key = event.logicalKey;

      if (_pressedKeys.remove(key)) {
        if (_pressedKeys.isEmpty) {
          _keyRepeatTimer?.cancel();
          _keyRepeatInitialDelayTimer?.cancel();
        } else if (_isHandledKey(key)) {
          // If there are still keys pressed, recalculate actions
          _setupKeyRepeatTimer();
        }
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  // Check if the key is one we handle for continuous actions
  bool _isHandledKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.minus ||
        key == LogicalKeyboardKey.numpadSubtract ||
        key == LogicalKeyboardKey.equal ||
        key == LogicalKeyboardKey.numpadAdd;
  }

  // Handle double-tap to zoom
  void _handleDoubleTap() {
    if (!widget.enableDoubleTapZoom || _doubleTapPosition == null) return;

    final RenderBox? box =
        _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final Offset localPosition = box.globalToLocal(_doubleTapPosition!);

    // Calculate focal point for zoom
    if (widget.controller.scale > (widget.minScale + widget.maxScale) / 2) {
      // If we're zoomed in, zoom out to minimum
      widget.controller.zoomOut(
        factor: widget.controller.scale / widget.minScale,
        focalPoint: localPosition,
      );
    } else {
      // Otherwise zoom in by the zoom factor
      widget.controller.zoomIn(
        factor: widget.doubleTapZoomFactor,
        focalPoint: localPosition,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (keyEvent) {
        _handleKeyEvent(_focusNode, keyEvent);
      },
      child: Listener(
        onPointerSignal: (PointerSignalEvent event) {
          if (event is PointerScrollEvent) {
            // Determine if scaling should occur based on ctrl key
            if (widget.enableCtrlScrollToScale && _isCtrlPressed) {
              // Get the pointer position as focal point
              final RenderBox? box = context.findRenderObject() as RenderBox?;
              if (box != null) {
                final Offset localPosition = box.globalToLocal(event.position);

                // Zoom in or out based on scroll direction
                if (event.scrollDelta.dy > 0) {
                  widget.controller.zoomOut(
                    factor: 1.05,
                    focalPoint: localPosition,
                    animate: false,
                  );
                } else {
                  widget.controller.zoomIn(
                    factor: 1.05,
                    focalPoint: localPosition,
                    animate: false,
                  );
                }

                if (widget.constrainBounds && widget.contentSize != null) {
                  widget.controller
                      .constrainToBounds(widget.contentSize!, box.size);
                }
              }
            } else {
              // Pan using scroll delta
              widget.controller.panBy(
                -event.scrollDelta,
                animate: false,
              );

              if (widget.constrainBounds && widget.contentSize != null) {
                final RenderBox? box = _viewportKey.currentContext
                    ?.findRenderObject() as RenderBox?;
                if (box != null) {
                  widget.controller
                      .constrainToBounds(widget.contentSize!, box.size);
                }
              }
            }
          }
        },
        child: GestureDetector(
          onScaleStart: (details) {
            _lastFocalPoint = details.focalPoint;
            _lastScale = widget.controller.scale;
            _lastRotation = widget.controller.rotation;

            // Request focus for keyboard interaction
            _focusNode.requestFocus();
          },
          onScaleUpdate: (details) {
            // Calculate updated scale with optional clamping
            double newScale = _lastScale * details.scale;
            newScale = newScale.clamp(widget.minScale, widget.maxScale);

            final Offset focalDiff = details.focalPoint - _lastFocalPoint;

            // Handle rotation if enabled
            double? newRotation;
            if (widget.enableRotation && details.pointerCount >= 2) {
              newRotation = _lastRotation + details.rotation;
            }

            widget.controller.update(
              newScale: newScale,
              newOffset: widget.controller.offset + focalDiff,
              newRotation: newRotation,
            );

            if (widget.constrainBounds && widget.contentSize != null) {
              final RenderBox? box =
                  _viewportKey.currentContext?.findRenderObject() as RenderBox?;
              if (box != null) {
                widget.controller
                    .constrainToBounds(widget.contentSize!, box.size);
              }
            }

            _lastFocalPoint = details.focalPoint;
          },
          onDoubleTapDown: widget.enableDoubleTapZoom
              ? (details) => _doubleTapPosition = details.globalPosition
              : null,
          onDoubleTap: widget.enableDoubleTapZoom ? _handleDoubleTap : null,
          child: LayoutBuilder(builder: (context, constraints) {
            return Container(
              color: Colors.transparent,
              child: ClipRRect(
                child: OverflowBox(
                  key: _viewportKey,
                  maxWidth: double.infinity,
                  maxHeight: double.infinity,
                  alignment: Alignment.topLeft,
                  child: Transform(
                    alignment: Alignment.topLeft,
                    transform: Matrix4.identity()
                      ..translate(widget.controller.offset.dx,
                          widget.controller.offset.dy)
                      ..scale(widget.controller.scale)
                      ..rotateZ(widget.enableRotation
                          ? widget.controller.rotation
                          : 0.0),
                    child: widget.child,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
