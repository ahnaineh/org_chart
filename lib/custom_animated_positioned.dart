import 'package:flutter/material.dart';

class CustomAnimatedPositioned extends AnimatedPositioned {
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
