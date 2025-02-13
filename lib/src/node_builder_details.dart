/// The details that are passed to the builder function
/// contains supported properties that can be used to build the node
class NodeBuilderDetails<T> {
  final T item;
  final int level;
  final void Function(bool? hide) hideNodes;
  final bool nodesHidden;
  final bool isBeingDragged;
  final bool isOverlapped;

  const NodeBuilderDetails({
    required this.item,
    required this.level,
    required this.hideNodes,
    required this.isBeingDragged,
    required this.isOverlapped,
    required this.nodesHidden,
  });
}
