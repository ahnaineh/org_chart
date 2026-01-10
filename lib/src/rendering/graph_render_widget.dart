import 'package:flutter/widgets.dart';
import 'package:org_chart/src/rendering/graph_parent_data.dart';
import 'package:org_chart/src/rendering/render_graph.dart';

class GraphRenderWidget extends MultiChildRenderObjectWidget {
  const GraphRenderWidget({
    super.key,
    required super.children,
    this.paintEdges,
    this.childConstraintsOverride,
  });

  final GraphEdgePainter? paintEdges;
  final BoxConstraints? childConstraintsOverride;

  @override
  RenderGraph createRenderObject(BuildContext context) {
    return RenderGraph(
      paintEdges: paintEdges,
      childConstraintsOverride: childConstraintsOverride,
      textDirection: Directionality.of(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderGraph renderObject) {
    renderObject
      ..paintEdges = paintEdges
      ..childConstraintsOverride = childConstraintsOverride
      ..textDirection = Directionality.of(context);
  }
}

class GraphChild extends ParentDataWidget<GraphParentData> {
  const GraphChild({
    super.key,
    required this.nodeId,
    required this.offset,
    this.isHitTestable = true,
    required super.child,
  });

  final String nodeId;
  final Offset offset;
  final bool isHitTestable;

  @override
  void applyParentData(RenderObject renderObject) {
    final GraphParentData parentData =
        renderObject.parentData! as GraphParentData;

    bool needsLayout = false;
    bool needsPaint = false;

    if (parentData.nodeId != nodeId) {
      parentData.nodeId = nodeId;
    }

    if (parentData.desiredOffset != offset) {
      parentData.desiredOffset = offset;
      needsLayout = true;
    }

    if (parentData.isHitTestable != isHitTestable) {
      parentData.isHitTestable = isHitTestable;
      needsPaint = true;
    }

    final RenderObject? parent = renderObject.parent;
    if (parent == null) return;
    if (needsLayout) parent.markNeedsLayout();
    if (needsPaint) parent.markNeedsPaint();
  }

  @override
  Type get debugTypicalAncestorWidgetClass => GraphRenderWidget;
}

class AnimatedGraphChild extends ImplicitlyAnimatedWidget {
  const AnimatedGraphChild({
    super.key,
    required this.nodeId,
    required this.offset,
    required super.duration,
    super.curve = Curves.linear,
    super.onEnd,
    this.isHitTestable = true,
    required this.child,
  });

  final String nodeId;
  final Offset offset;
  final bool isHitTestable;
  final Widget child;

  @override
  ImplicitlyAnimatedWidgetState<AnimatedGraphChild> createState() =>
      _AnimatedGraphChildState();
}

class _AnimatedGraphChildState
    extends AnimatedWidgetBaseState<AnimatedGraphChild> {
  Tween<Offset>? _offsetTween;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _offsetTween = visitor(
      _offsetTween,
      widget.offset,
      (dynamic value) => Tween<Offset>(begin: value as Offset),
    ) as Tween<Offset>?;
  }

  @override
  Widget build(BuildContext context) {
    return GraphChild(
      nodeId: widget.nodeId,
      offset: _offsetTween?.evaluate(animation) ?? widget.offset,
      isHitTestable: widget.isHitTestable,
      child: widget.child,
    );
  }
}
