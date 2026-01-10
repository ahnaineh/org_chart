import 'layout_graph.dart';
import 'layout_node.dart';

/// OrgChart relationships expressed as a parent pointer per node id.
///
/// A `null` parent indicates a root node.
class OrgChartLayoutGraph implements LayoutGraph {
  @override
  final Map<String, LayoutNode> nodes;

  /// Maps a node id to its parent id.
  final Map<String, String?> parentById;

  OrgChartLayoutGraph({required this.nodes, required this.parentById});

  String? parentOf(String nodeId) => parentById[nodeId];
}
