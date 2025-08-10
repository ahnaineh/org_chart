import 'package:flutter/animation.dart';
import 'package:org_chart/src/common/node.dart';
import 'package:org_chart/src/base/base_controller.dart';
import 'package:org_chart/src/orgchart/org_chart_constants.dart';
import 'mixins/node_query_mixin.dart';
import 'mixins/node_modification_mixin.dart';
import 'mixins/node_positioning_mixin.dart';

enum ActionOnNodeRemoval {
  unlinkDescendants,
  connectDescendantsToParent,
  removeDescendants
}

/// Controller specifically for organizational charts
class OrgChartController<E> extends BaseGraphController<E>
    with NodeQueryMixin<E>, NodeModificationMixin<E>, NodePositioningMixin<E> {
  // /// Get the current orientation of the chart
  // OrgChartOrientation get orientation => _orientation;

  /// Get the "to" ID of a node
  @override
  String? Function(E data) toProvider;

  /// replace the item with updated to ID
  @override
  E Function(E data, String? newID)? toSetter;

  /// Number of columns to arrange leaf nodes in (default: 2)
  int leafColumns;

  OrgChartController({
    required super.items,
    super.boxSize = OrgChartConstants.defaultBoxSize,
    super.spacing = OrgChartConstants.defaultSpacing,
    super.runSpacing = OrgChartConstants.defaultRunSpacing,
    super.orientation = GraphOrientation.topToBottom,
    required super.idProvider,
    required this.toProvider,
    this.toSetter,
    this.leafColumns = OrgChartConstants.defaultLeafColumns,
  }) {
    // Build initial indexes
    rebuildChildrenIndex();
    rebuildQuadTree();

    // Calculate positions now that all initialization is complete
    calculatePosition();
  }

  @override
  void addItem(E item,
      {bool recalculatePosition = true, bool centerGraph = false}) {
    super.addItem(item,
        recalculatePosition: recalculatePosition, centerGraph: centerGraph);
    clearCachesAndRebuildIndexes();
  }

  @override
  void addItems(List<E> items,
      {bool recalculatePosition = true, bool centerGraph = false}) {
    super.addItems(items,
        recalculatePosition: recalculatePosition, centerGraph: centerGraph);
    clearCachesAndRebuildIndexes();
  }

  @override
  void clearItems({bool recalculatePosition = true, bool centerGraph = false}) {
    super.clearItems(
        recalculatePosition: recalculatePosition, centerGraph: centerGraph);
    clearCachesAndRebuildIndexes();
  }

  @override
  void replaceAll(List<E> items,
      {bool recalculatePosition = true, bool centerGraph = false}) {
    super.replaceAll(items,
        recalculatePosition: recalculatePosition, centerGraph: centerGraph);
    clearCachesAndRebuildIndexes();
  }

  // Node-related methods
  @override
  List<Node<E>> get roots =>
      nodes.where((node) => getLevel(node) == 1).toList();

  @override
  Future<void> centerNode(String nodeId,
      {double? scale,
      bool animate = true,
      Duration duration = const Duration(milliseconds: 300),
      Curve curve = Curves.easeInOut}) async {
    final node =
        nodes.where((node) => idProvider(node.data) == nodeId).firstOrNull;
    if (node == null || isNodeHidden(node)) return;
    return super.centerNode(nodeId,
        scale: scale, animate: animate, duration: duration, curve: curve);
  }
}
