import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:org_chart/src/rendering/graph_parent_data.dart';

typedef GraphEdgePainter = void Function(Canvas canvas, Size size);

class RenderGraph extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, GraphParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, GraphParentData> {
  RenderGraph({
    GraphEdgePainter? paintEdges,
    BoxConstraints? childConstraintsOverride,
    TextDirection textDirection = TextDirection.ltr,
  })  : _paintEdges = paintEdges,
        _childConstraintsOverride = childConstraintsOverride,
        _textDirection = textDirection;

  GraphEdgePainter? _paintEdges;
  GraphEdgePainter? get paintEdges => _paintEdges;
  set paintEdges(GraphEdgePainter? value) {
    if (identical(value, _paintEdges)) return;
    _paintEdges = value;
    markNeedsPaint();
  }

  BoxConstraints? _childConstraintsOverride;
  BoxConstraints? get childConstraintsOverride => _childConstraintsOverride;
  set childConstraintsOverride(BoxConstraints? value) {
    if (value == _childConstraintsOverride) return;
    _childConstraintsOverride = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  TextDirection get textDirection => _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! GraphParentData) {
      child.parentData = GraphParentData();
    }
  }

  @override
  void performLayout() {
    final BoxConstraints childConstraints = _childConstraintsOverride == null
        ? constraints.loosen()
        : _childConstraintsOverride!.enforce(constraints.loosen());

    double maxRight = 0.0;
    double maxBottom = 0.0;

    RenderBox? child = firstChild;
    while (child != null) {
      final GraphParentData parentData = child.parentData! as GraphParentData;

      child.layout(childConstraints, parentUsesSize: true);

      maxRight =
          math.max(maxRight, parentData.desiredOffset.dx + child.size.width);
      maxBottom =
          math.max(maxBottom, parentData.desiredOffset.dy + child.size.height);

      child = parentData.nextSibling;
    }

    final Size contentSize = Size(maxRight, maxBottom);
    size = constraints.constrain(contentSize);

    child = firstChild;
    while (child != null) {
      final GraphParentData parentData = child.parentData! as GraphParentData;
      final Offset desired = parentData.desiredOffset;

      parentData.offset = switch (_textDirection) {
        TextDirection.ltr => desired,
        TextDirection.rtl =>
          Offset(size.width - desired.dx - child.size.width, desired.dy),
      };

      child = parentData.nextSibling;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_paintEdges case final GraphEdgePainter painter) {
      context.canvas.save();
      context.canvas.translate(offset.dx, offset.dy);
      painter(context.canvas, size);
      context.canvas.restore();
    }

    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    RenderBox? child = lastChild;
    while (child != null) {
      final GraphParentData parentData = child.parentData! as GraphParentData;
      if (parentData.isHitTestable) {
        final bool isHit = result.addWithPaintOffset(
          offset: parentData.offset,
          position: position,
          hitTest: (BoxHitTestResult result, Offset transformed) {
            return child!.hitTest(result, position: transformed);
          },
        );
        if (isHit) return true;
      }
      child = parentData.previousSibling;
    }
    return false;
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final GraphParentData parentData = child.parentData! as GraphParentData;
    transform.translateByDouble(
      parentData.offset.dx,
      parentData.offset.dy,
      0.0,
      1.0,
    );
  }
}
