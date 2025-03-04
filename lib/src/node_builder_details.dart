/// Contains all necessary properties that are passed to the node builder function
/// to customize the appearance and behavior of each node in the organization chart.
class NodeBuilderDetails<T> {
  /// The data item associated with this node
  final T item;
  
  /// The depth level of the node in the hierarchy (starts at 1 for root nodes)
  final int level;
  
  /// Function to toggle the visibility of children nodes
  /// - Pass true to hide subnodes
  /// - Pass false to show subnodes
  /// - Pass null to toggle current state
  final void Function(bool? hide) hideNodes;
  
  /// Whether the subnodes of this node are currently hidden/collapsed
  final bool nodesHidden;
  
  /// Whether this node is currently being dragged
  final bool isBeingDragged;
  
  /// Whether this node is currently being overlapped by another dragged node
  final bool isOverlapped;

  /// Creates a details object with all required node properties
  const NodeBuilderDetails({
    required this.item,
    required this.level,
    required this.hideNodes,
    required this.nodesHidden,
    required this.isBeingDragged,
    required this.isOverlapped,
  });
  
  /// Creates a copy of this object with the specified fields replaced
  NodeBuilderDetails<T> copyWith({
    T? item,
    int? level,
    void Function(bool? hide)? hideNodes,
    bool? nodesHidden,
    bool? isBeingDragged,
    bool? isOverlapped,
  }) {
    return NodeBuilderDetails<T>(
      item: item ?? this.item,
      level: level ?? this.level,
      hideNodes: hideNodes ?? this.hideNodes,
      nodesHidden: nodesHidden ?? this.nodesHidden,
      isBeingDragged: isBeingDragged ?? this.isBeingDragged,
      isOverlapped: isOverlapped ?? this.isOverlapped,
    );
  }
}
