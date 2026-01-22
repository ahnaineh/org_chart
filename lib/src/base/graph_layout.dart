import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:org_chart/src/base/base_controller.dart';
import 'package:org_chart/src/base/collision_avoidance.dart';
import 'package:org_chart/src/common/node.dart';

class GraphLayout<E> extends MultiChildRenderObjectWidget {
  final BaseGraphController<E> controller;
  final AnimationController animationController;
  final Curve curve;
  final TextDirection textDirection;

  const GraphLayout({
    super.key,
    required this.controller,
    required this.animationController,
    required this.curve,
    required this.textDirection,
    required super.children,
  });

  @override
  RenderGraphLayout<E> createRenderObject(BuildContext context) {
    return RenderGraphLayout<E>(
      controller: controller,
      animationController: animationController,
      curve: curve,
      textDirection: textDirection,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderGraphLayout<E> renderObject,
  ) {
    renderObject
      ..controller = controller
      ..animationController = animationController
      ..curve = curve
      ..textDirection = textDirection;
    if (controller.isLayoutRequested) {
      renderObject.markNeedsLayout();
    }
  }
}

class GraphNode<E> extends ParentDataWidget<GraphLayoutParentData<E>> {
  final Node<E> node;
  final bool isBeingDragged;

  const GraphNode({
    super.key,
    required this.node,
    this.isBeingDragged = false,
    required super.child,
  });

  @override
  void applyParentData(RenderObject renderObject) {
    final GraphLayoutParentData<E> parentData =
        renderObject.parentData! as GraphLayoutParentData<E>;
    bool needsLayout = false;

    if (parentData.node != node) {
      parentData.node = node;
      needsLayout = true;
    }

    if (parentData.isBeingDragged != isBeingDragged) {
      parentData.isBeingDragged = isBeingDragged;
      needsLayout = true;
    }

    if (needsLayout) {
      final RenderObject? parent = renderObject.parent;
      if (parent is RenderObject) {
        parent.markNeedsLayout();
      }
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => GraphLayout<E>;
}

class GraphLayoutParentData<E> extends ContainerBoxParentData<RenderBox> {
  Node<E>? node;
  bool isBeingDragged = false;
}

class RenderGraphLayout<E> extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, GraphLayoutParentData<E>>,
        RenderBoxContainerDefaultsMixin<RenderBox, GraphLayoutParentData<E>> {
  BaseGraphController<E> _controller;
  AnimationController _animationController;
  Curve _curve;
  TextDirection _textDirection;

  final Map<Node<E>, Offset> _startPositions = {};
  bool _isAnimating = false;
  bool _deferredExplicitLayout = false;
  bool _deferredCollision = false;
  bool _hasLaidOut = false;

  RenderGraphLayout({
    required BaseGraphController<E> controller,
    required AnimationController animationController,
    required Curve curve,
    required TextDirection textDirection,
  })  : _controller = controller,
        _animationController = animationController,
        _curve = curve,
        _textDirection = textDirection {
    _animationController.addListener(_handleAnimationTick);
  }

  BaseGraphController<E> get controller => _controller;
  set controller(BaseGraphController<E> value) {
    if (_controller == value) return;
    _controller = value;
    _hasLaidOut = false;
    markNeedsLayout();
  }

  AnimationController get animationController => _animationController;
  set animationController(AnimationController value) {
    if (_animationController == value) return;
    _animationController.removeListener(_handleAnimationTick);
    _animationController = value;
    _animationController.addListener(_handleAnimationTick);
    markNeedsLayout();
  }

  Curve get curve => _curve;
  set curve(Curve value) {
    if (_curve == value) return;
    _curve = value;
    markNeedsPaint();
  }

  TextDirection get textDirection => _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    markNeedsPaint();
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! GraphLayoutParentData<E>) {
      child.parentData = GraphLayoutParentData<E>();
    }
  }

  @override
  void detach() {
    _animationController.removeListener(_handleAnimationTick);
    super.detach();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _animationController.addListener(_handleAnimationTick);
  }

  @override
  void performLayout() {
    final BoxConstraints childConstraints = constraints.loosen();
    bool sizeChanged = false;
    bool sizeChangeCollisionRequested = false;

    RenderBox? child = firstChild;
    while (child != null) {
      final GraphLayoutParentData<E> parentData =
          child.parentData! as GraphLayoutParentData<E>;
      child.layout(childConstraints, parentUsesSize: true);
      final Node<E>? node = parentData.node;
      if (node != null) {
        final Size previousSize = node.size;
        node.size = child.size;
        if (previousSize != child.size) {
          sizeChanged = true;
        }
        if (controller.sizeChangeAction ==
                SizeChangeAction.collisionAvoidance &&
            _isSizeChangeSignificant(previousSize, child.size)) {
          sizeChangeCollisionRequested = true;
        }
      }
      child = parentData.nextSibling;
    }

    final bool explicitLayoutRequested = controller.isLayoutRequested;
    final bool isDragging = _isAnyNodeDragging();
    final bool hasPendingLayout =
        explicitLayoutRequested || _deferredExplicitLayout;
    final bool hasPendingCollision =
        sizeChangeCollisionRequested || _deferredCollision;

    bool layoutPerformed = false;
    bool collisionPerformed = false;

    if (hasPendingLayout) {
      if (isDragging) {
        _deferredExplicitLayout = true;
      } else {
        if (explicitLayoutRequested) {
          controller.consumeLayoutRequest();
        }
        _deferredExplicitLayout = false;
        controller.performLayout();
        layoutPerformed = true;
      }
    }

    if (hasPendingCollision) {
      if (isDragging) {
        _deferredCollision = true;
      } else if (controller.sizeChangeAction ==
          SizeChangeAction.collisionAvoidance) {
        _deferredCollision = false;
        final Set<String> pinnedIds =
            controller.preserveManualPositionsOnSizeChange
                ? controller.manualPositionIds
                : <String>{};
        collisionPerformed = CollisionAvoidance.resolveGlobal(
          nodes: controller.nodes,
          idProvider: controller.idProvider,
          pinnedIds: pinnedIds,
          settings: controller.collisionSettings,
        );
      } else {
        _deferredCollision = false;
      }
    }

    if (layoutPerformed || collisionPerformed || sizeChanged) {
      controller.onLayoutComplete();
    }

    final Size contentSize = _calculateContentSize();
    controller.updateContentSize(contentSize);
    size = constraints.constrain(contentSize);

    if (layoutPerformed) {
      final bool shouldCenter = controller.consumeCenterAfterLayout();
      if (shouldCenter) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          controller.centerGraph?.call();
        });
      }
    }

    _syncParentOffsets();
    if (_hasLaidOut) {
      _maybeStartAnimation(layoutPerformed || collisionPerformed);
    } else {
      _isAnimating = false;
      _animationController.stop();
    }
    _applyRenderPositions();
    _hasLaidOut = true;
  }

  bool _isAnyNodeDragging() {
    RenderBox? child = firstChild;
    while (child != null) {
      final GraphLayoutParentData<E> parentData =
          child.parentData! as GraphLayoutParentData<E>;
      if (parentData.isBeingDragged) {
        return true;
      }
      child = parentData.nextSibling;
    }
    return false;
  }

  bool _isSizeChangeSignificant(Size previous, Size current) {
    if (previous == current) return false;
    final double threshold =
        controller.sizeChangeThreshold < 0 ? 0 : controller.sizeChangeThreshold;
    final double widthDelta = (previous.width - current.width).abs();
    final double heightDelta = (previous.height - current.height).abs();
    return widthDelta > threshold || heightDelta > threshold;
  }

  Size _calculateContentSize() {
    double maxX = 0;
    double maxY = 0;
    RenderBox? child = firstChild;
    while (child != null) {
      final GraphLayoutParentData<E> parentData =
          child.parentData! as GraphLayoutParentData<E>;
      final Node<E>? node = parentData.node;
      if (node != null) {
        maxX = mathMax(maxX, node.position.dx + node.size.width);
        maxY = mathMax(maxY, node.position.dy + node.size.height);
      }
      child = parentData.nextSibling;
    }
    return Size(maxX, maxY);
  }

  void _syncParentOffsets() {
    RenderBox? child = firstChild;
    while (child != null) {
      final GraphLayoutParentData<E> parentData =
          child.parentData! as GraphLayoutParentData<E>;
      final Node<E>? node = parentData.node;
      if (node != null) {
        parentData.offset = node.position;
      }
      child = parentData.nextSibling;
    }
  }

  void _maybeStartAnimation(bool layoutUpdated) {
    if (!layoutUpdated) return;

    bool positionsChanged = false;
    RenderBox? child = firstChild;
    while (child != null) {
      final GraphLayoutParentData<E> parentData =
          child.parentData! as GraphLayoutParentData<E>;
      final Node<E>? node = parentData.node;
      if (node != null && !parentData.isBeingDragged) {
        if (node.renderPosition != node.position) {
          positionsChanged = true;
          break;
        }
      }
      child = parentData.nextSibling;
    }

    if (!positionsChanged) {
      _isAnimating = false;
      _animationController.stop();
      return;
    }

    _startPositions.clear();
    child = firstChild;
    while (child != null) {
      final GraphLayoutParentData<E> parentData =
          child.parentData! as GraphLayoutParentData<E>;
      final Node<E>? node = parentData.node;
      if (node != null) {
        _startPositions[node] = node.renderPosition;
      }
      child = parentData.nextSibling;
    }

    _isAnimating = _animationController.duration != Duration.zero;
    if (_isAnimating) {
      _animationController.forward(from: 0.0);
    } else {
      _animationController.value = 1.0;
    }
  }

  void _handleAnimationTick() {
    if (!_isAnimating) {
      return;
    }
    _applyRenderPositions();
    if (_animationController.isCompleted) {
      _isAnimating = false;
    }
    markNeedsPaint();
  }

  void _applyRenderPositions() {
    final double t = _curve.transform(_animationController.value);
    RenderBox? child = firstChild;
    while (child != null) {
      final GraphLayoutParentData<E> parentData =
          child.parentData! as GraphLayoutParentData<E>;
      final Node<E>? node = parentData.node;
      if (node != null) {
        if (parentData.isBeingDragged) {
          node.renderPosition = node.position;
        } else if (_isAnimating) {
          final Offset start = _startPositions[node] ?? node.renderPosition;
          node.renderPosition = Offset.lerp(start, node.position, t)!;
        } else {
          node.renderPosition = node.position;
        }
      }
      child = parentData.nextSibling;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    RenderBox? child = firstChild;
    while (child != null) {
      final GraphLayoutParentData<E> parentData =
          child.parentData! as GraphLayoutParentData<E>;
      final Node<E>? node = parentData.node;
      Offset childOffset = parentData.offset;
      if (node != null) {
        childOffset = node.renderPosition;
        if (_textDirection == TextDirection.rtl) {
          childOffset = Offset(
            size.width - childOffset.dx - node.size.width,
            childOffset.dy,
          );
        }
      }
      context.paintChild(child, offset + childOffset);
      child = parentData.nextSibling;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    RenderBox? child = lastChild;
    while (child != null) {
      final GraphLayoutParentData<E> parentData =
          child.parentData! as GraphLayoutParentData<E>;
      final Node<E>? node = parentData.node;
      Offset childOffset = parentData.offset;
      if (node != null) {
        childOffset = node.renderPosition;
        if (_textDirection == TextDirection.rtl) {
          childOffset = Offset(
            size.width - childOffset.dx - node.size.width,
            childOffset.dy,
          );
        }
      }

      final bool isHit = result.addWithPaintOffset(
        offset: childOffset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          return child!.hitTest(result, position: transformed);
        },
      );

      if (isHit) {
        return true;
      }
      child = parentData.previousSibling;
    }
    return false;
  }
}

double mathMax(double a, double b) => a > b ? a : b;
