import 'layout_graph.dart';
import 'layout_node.dart';

/// Per-person relationship pointers required for Genogram layout.
class GenogramPersonRelations {
  final String? fatherId;
  final String? motherId;
  final Set<String> spouseIds;

  const GenogramPersonRelations({
    this.fatherId,
    this.motherId,
    this.spouseIds = const {},
  });

  @override
  String toString() =>
      'GenogramPersonRelations(fatherId: $fatherId, motherId: $motherId, '
      'spouseIds: $spouseIds)';
}

/// Genogram relationships expressed as parent pointers and spouse sets.
class GenogramLayoutGraph implements LayoutGraph {
  @override
  final Map<String, LayoutNode> nodes;

  /// Maps a person id to their relationship pointers.
  final Map<String, GenogramPersonRelations> relationsById;

  GenogramLayoutGraph({required this.nodes, this.relationsById = const {}});

  GenogramPersonRelations relationsOf(String personId) =>
      relationsById[personId] ?? const GenogramPersonRelations();
}
