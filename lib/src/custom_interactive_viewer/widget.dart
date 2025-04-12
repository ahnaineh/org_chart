import 'package:flutter/material.dart';
import 'package:org_chart/src/custom_interactive_viewer/controller.dart';

class CustomInteractiveViewer extends StatefulWidget {
  final Widget child;
  final CustomInteractiveViewerController controller;
  // Optionally, if you know the intrinsic content size,
  // you can pass it so centering can be computed automatically.
  final Size? contentSize;

  const CustomInteractiveViewer({
    super.key,
    required this.child,
    required this.controller,
    this.contentSize,
  });

  @override
  State<CustomInteractiveViewer> createState() =>
      _CustomInteractiveViewerState();
}

class _CustomInteractiveViewerState extends State<CustomInteractiveViewer> {
  Offset _lastFocalPoint = Offset.zero;
  double _lastScale = 1.0;
  // Global key to measure the container size for centering.
  final GlobalKey _viewportKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
    // Optionally, center after the first frame if a contentSize is provided.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.contentSize != null) {
        _centerContent();
      }
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() => setState(() {});

  /// Helper: centers the content using the provided contentSize.
  void _centerContent() {
    if (widget.contentSize == null) return;
    final RenderBox? box =
        _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final Size viewportSize = box.size;
    widget.controller.center(viewportSize, widget.contentSize!);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return GestureDetector(
        onScaleStart: (details) {
          _lastFocalPoint = details.focalPoint;
          _lastScale = widget.controller.scale;
        },
        onScaleUpdate: (details) {
          // Calculate updated scale. Optionally, adjust min/max values.
          double newScale = _lastScale * details.scale;
          newScale = newScale.clamp(0.5, 4.0);

          // Calculate pan by the difference in focal points.
          final Offset focalDiff = details.focalPoint - _lastFocalPoint;

          // Update the controller.
          widget.controller.update(
            newScale: newScale,
            newOffset: widget.controller.offset + focalDiff,
          );

          // Set last focal for continuous movement.
          _lastFocalPoint = details.focalPoint;
        },
        // For example, double-tap to center content.
        onDoubleTap: () => _centerContent(),
        child: ClipRect(
          child: Container(
            key: _viewportKey,
            color: Colors.transparent,
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: Transform(
              transform: Matrix4.identity()
                ..translate(
                    widget.controller.offset.dx, widget.controller.offset.dy)
                ..scale(widget.controller.scale),
              child: widget.child,
            ),
          ),
        ),
      );
    });
  }
}
