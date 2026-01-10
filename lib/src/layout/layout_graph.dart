import 'layout_node.dart';

/// Base graph input for a layout run.
abstract class LayoutGraph {
  Map<String, LayoutNode> get nodes;
}
