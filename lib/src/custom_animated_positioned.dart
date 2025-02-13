import 'package:flutter/material.dart';

/// CustomAnimatedPositioned is almost identical to AnimatedPositioned
/// only integrating the isBeingDragged property to enable us to set the node being dragged at front
class CustomAnimatedPositioned extends AnimatedPositioned {
  /// Whether the node is being dragged or not
  final bool isBeingDragged;
  const CustomAnimatedPositioned({
    super.key,
    required super.child,
    required super.duration,
    this.isBeingDragged = false,
    super.curve,
    super.onEnd,
    super.top,
    super.right,
    super.bottom,
    super.left,
    super.width,
    super.height,
  });
}
