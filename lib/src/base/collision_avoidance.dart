import 'package:flutter/material.dart';
import 'package:org_chart/src/common/node.dart';

class CollisionAvoidanceSettings {
  final int maxIterations;
  final double padding;
  final double minSeparation;

  const CollisionAvoidanceSettings({
    this.maxIterations = 8,
    this.padding = 0,
    this.minSeparation = 0.5,
  });
}

class CollisionAvoidance {
  static bool resolveGlobal<E>({
    required List<Node<E>> nodes,
    required String Function(E data) idProvider,
    Set<String> pinnedIds = const {},
    CollisionAvoidanceSettings settings = const CollisionAvoidanceSettings(),
  }) {
    if (nodes.length < 2) return false;

    bool anyMoved = false;
    final double padding = settings.padding;
    final double minSeparation = settings.minSeparation;

    for (int iteration = 0; iteration < settings.maxIterations; iteration++) {
      bool movedThisIteration = false;

      for (int i = 0; i < nodes.length; i++) {
        final Node<E> nodeA = nodes[i];
        final bool pinA = pinnedIds.contains(idProvider(nodeA.data));

        for (int j = i + 1; j < nodes.length; j++) {
          final Node<E> nodeB = nodes[j];
          final bool pinB = pinnedIds.contains(idProvider(nodeB.data));

          if (pinA && pinB) continue;

          final Rect rectA = _rectFor(nodeA, padding);
          final Rect rectB = _rectFor(nodeB, padding);

          if (!rectA.overlaps(rectB)) continue;

          final double overlapX =
              mathMin(rectA.right, rectB.right) -
                  mathMax(rectA.left, rectB.left);
          final double overlapY =
              mathMin(rectA.bottom, rectB.bottom) -
                  mathMax(rectA.top, rectB.top);

          if (overlapX <= 0 || overlapY <= 0) continue;

          final bool separateHorizontally = overlapX <= overlapY;
          if (separateHorizontally) {
            final double separation = overlapX + minSeparation;
            final double direction =
                rectA.center.dx < rectB.center.dx ? -1.0 : 1.0;
            _applySeparation(
              nodeA: nodeA,
              nodeB: nodeB,
              pinA: pinA,
              pinB: pinB,
              deltaA: Offset(direction * separation, 0),
            );
          } else {
            final double separation = overlapY + minSeparation;
            final double direction =
                rectA.center.dy < rectB.center.dy ? -1.0 : 1.0;
            _applySeparation(
              nodeA: nodeA,
              nodeB: nodeB,
              pinA: pinA,
              pinB: pinB,
              deltaA: Offset(0, direction * separation),
            );
          }

          movedThisIteration = true;
        }
      }

      if (movedThisIteration) {
        anyMoved = true;
      } else {
        break;
      }
    }

    return anyMoved;
  }

  static Rect _rectFor<E>(Node<E> node, double padding) {
    return Rect.fromLTWH(
      node.position.dx - padding,
      node.position.dy - padding,
      node.size.width + padding * 2,
      node.size.height + padding * 2,
    );
  }

  static void _applySeparation<E>({
    required Node<E> nodeA,
    required Node<E> nodeB,
    required bool pinA,
    required bool pinB,
    required Offset deltaA,
  }) {
    if (!pinA && !pinB) {
      nodeA.position += deltaA / 2;
      nodeB.position -= deltaA / 2;
      return;
    }

    if (!pinA) {
      nodeA.position += deltaA;
    } else if (!pinB) {
      nodeB.position -= deltaA;
    }
  }
}

double mathMin(double a, double b) => a < b ? a : b;
double mathMax(double a, double b) => a > b ? a : b;
