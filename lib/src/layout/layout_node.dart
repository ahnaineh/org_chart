import 'dart:ui';

/// A node participating in a layout run.
///
/// This type is widget-agnostic and only carries the minimum geometry needed
/// for layout math.
class LayoutNode {
  final String id;
  final Size size;

  const LayoutNode({required this.id, required this.size});

  @override
  String toString() => 'LayoutNode(id: $id, size: $size)';
}
