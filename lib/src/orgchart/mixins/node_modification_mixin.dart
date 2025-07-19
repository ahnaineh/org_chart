import 'package:org_chart/src/common/node.dart';
import '../org_chart_controller.dart';

/// Mixin for node modification utilities for OrgChartController
mixin NodeModificationMixin<E> {
  List<Node<E>> get nodes;
  String Function(E data) get idProvider;
  String? Function(E data) get toProvider;
  E Function(E data, String? newID)? get toSetter;
  void addItem(E item, {bool recalculatePosition, bool centerGraph});
  void calculatePosition({bool center});
  void clearCachesAndRebuildIndexes();

  /// Remove an item from the chart
  void removeItem(String? id, ActionOnNodeRemoval action,
      {bool recalculatePosition = true, bool centerGraph = false}) {
    if (action == ActionOnNodeRemoval.unlinkDescendants ||
        action == ActionOnNodeRemoval.connectDescendantsToParent) {
      assert(toSetter != null,
          "toSetter is not provided, you can't use this function without providing a toSetter");
    }

    final nodeToRemove =
        nodes.where((element) => idProvider(element.data) == id).firstOrNull;
    if (nodeToRemove == null) return;

    // Clear caches when removing nodes
    clearCachesAndRebuildIndexes();

    final subnodes =
        nodes.where((element) => toProvider(element.data) == id).toList();

    for (Node<E> node in subnodes) {
      switch (action) {
        case ActionOnNodeRemoval.unlinkDescendants:
          addItem(
            toSetter!(node.data, null),
            recalculatePosition: false,
            centerGraph: false,
          );
          break;
        case ActionOnNodeRemoval.connectDescendantsToParent:
          addItem(
            toSetter!(node.data, toProvider(nodeToRemove.data)),
            recalculatePosition: false,
            centerGraph: false,
          );
          break;
        case ActionOnNodeRemoval.removeDescendants:
          _removeNodeAndDescendants(nodes, node);
          break;
      }
    }

    nodes.remove(nodeToRemove);
    if (recalculatePosition) {
      calculatePosition(center: centerGraph);
    }
  }

  void removeItems(List<String> ids, ActionOnNodeRemoval action,
      {bool recalculatePosition = true, bool centerGraph = false}) {
    for (final id in ids) {
      removeItem(id, action, recalculatePosition: false, centerGraph: false);
    }
    if (recalculatePosition) {
      calculatePosition(center: centerGraph);
    }
  }

  /// Updates an existing item in the chart
  /// If the item with the given ID doesn't exist, it will be added
  void updateItem(E item, {bool recalculatePosition = true, bool centerGraph = false}) {
    final itemId = idProvider(item);
    final existingIndex = nodes.indexWhere((node) => idProvider(node.data) == itemId);
    
    if (existingIndex != -1) {
      // Replace existing item
      nodes[existingIndex] = Node(data: item);
    } else {
      // Add new item if it doesn't exist
      nodes.add(Node(data: item));
    }
    
    // Clear caches and rebuild indexes when updating
    clearCachesAndRebuildIndexes();
    
    if (recalculatePosition) {
      calculatePosition(center: centerGraph);
    }
  }

  /// Updates multiple items in the chart
  void updateItems(List<E> items, {bool recalculatePosition = true, bool centerGraph = false}) {
    for (final item in items) {
      updateItem(item, recalculatePosition: false, centerGraph: false);
    }
    
    if (recalculatePosition) {
      calculatePosition(center: centerGraph);
    }
  }

  /// Removes a node and all its descendants from the list of nodes
  void _removeNodeAndDescendants(List<Node<E>> nodes, Node<E> nodeToRemove) {
    Set<Node<E>> nodesToRemove = {};

    void collectDescendantNodes(Node<E> currentNode) {
      nodesToRemove.add(currentNode);

      final nodeId = idProvider(currentNode.data);
      final subnodes =
          nodes.where((element) => toProvider(element.data) == nodeId);

      for (final node in subnodes) {
        collectDescendantNodes(node);
      }
    }

    collectDescendantNodes(nodeToRemove);
    nodes.removeWhere((node) => nodesToRemove.contains(node));
  }
}
