import 'package:flutter/material.dart';
import 'package:org_chart/node.dart';
import 'dart:math' as math;

/// The main class the capsulates all the data and all the functions needed to calculate node positions
class Graph<E> {
  /// The list of nodes that we want to draw. this is generated from the items list.
  late List<Node<E>> _nodes;

  /// The size of each node box. Needed to determine it here and not in the contentBuilder function
  /// because I need this value for the calculations
  Size boxSize;

  /// The spacing between each node box. Needed here for the same reason i need boxSize here.
  Size spacing;

  /// The following function is included to ease the use of custom data types
  /// whether it be a map with key 'id' or 'pk' or a custom class, just use this function to provide the ids
  /// The function that returns the id of the node.
  String? Function(E data) idProvider;

  /// The following function is included to ease the use of custom data types
  /// whether it be a map with key 'id' or 'pk' or a custom class, just use this function to provide the ids
  /// The function that returns the id of the node that the current node is pointing to.
  String? Function(E data) toProvider;

  Graph({
    required List<E> items,
    this.boxSize = const Size(200, 100),
    this.spacing = const Size(20, 50),
    required this.idProvider,
    required this.toProvider,
  }) : super() {
    this.items = items;
  }

  /// returns the list of items showed in the graph
  /// use the remove item if you want to remove an item from the list
  List<E> get items => _nodes.map((e) => e.data).toList();

  /// to add an item
  set items(List<E> items) {
    _nodes = items.map((e) => Node(data: e)).toList();
    calculatePosition();
  }

  /// to remove an item from the list
  void removeItem(id) {
    _nodes.removeWhere((element) => idProvider(element.data) == id);
    calculatePosition();
  }

  /// to generate a unique id for an item
  /// this is used when you want to add an item to the list
  /// and you don't want to provide an id for it
  /// you might want to get an id from the server, but in case of a local list you can use this function
  String get uniqueNodeId {
    int id = 0;
    while (_nodes.any((element) => idProvider(element.data) == id.toString())) {
      id++;
    }
    return id.toString();
  }

  /// to add an item to the list
  /// position will be calculated afterwards
  void addItem(E item) {
    _nodes.add(Node(data: item));
    calculatePosition();
  }

  /// returns the level of the node
  /// used to determine the Y offset of the node
  _getLevel(Node<E> node) {
    int level = 1;
    Node<E>? next = node;
    while (next != null) {
      try {
        next = _nodes
            .firstWhere((n) => idProvider(n.data) == toProvider(next!.data));
        level++;
      } catch (e) {
        next = null;
      }
    }
    return level;
  }

  /// returns the list of root nodes
  List<Node<E>> get roots {
    return _nodes
        .where((node) => _nodes
            .where(
                (element) => idProvider(element.data) == toProvider(node.data))
            .isEmpty)
        .toList();
  }

  /// changes the index of the node in the list, if index is -1 then it will be moved to the end of the list
  /// this is used on drag start to move the dragged node to the end of the list so that it will be drawn on top
  void changeNodeIndex(Node<E> node, index) {
    _nodes.remove(node);
    _nodes.insert(index == -1 ? math.max(_nodes.length - 1, 0) : index, node);
  }

  // reutns the relative X offset of the node
  double _getRelOffset(Node<E> node) {
    List<Node<E>> subNodes = getSubNodes(node);

    if (node.hideNodes || subNodes.isEmpty) {
      return boxSize.width + spacing.width * 2;
    }

    double relativeOffset = 0.0;

    if (allLeaf(subNodes)) {
      return (subNodes.length > 1
          ? boxSize.width * 2 + spacing.width * 3
          : boxSize.width + spacing.width * 2);
    } else {
      for (var i = 0; i < subNodes.length; i++) {
        relativeOffset += _getRelOffset(subNodes[i]);
      }
    }
    return relativeOffset;
  }

  /// returns true if all the nodes in the list are leaves nodes
  bool allLeaf(List<Node<E>> nodes) {
    return nodes
        .every((element) => getSubNodes(element).isEmpty || element.hideNodes);
  }

  /// returns the list of nodes that are pointing to the input node
  List<Node<E>> getSubNodes(Node<E> node) {
    return _nodes
        .where((element) => toProvider(element.data) == idProvider(node.data))
        .toList();
  }

  /// function recursively calculates the position of the node and its subnodes
  /// returns relative offset of the node
  double _calculateNP(Node<E> node, {Offset offset = const Offset(0, 0)}) {
    List<Node<E>> subNodes = getSubNodes(node);

    /// if all the sub nodes are leaves, then draw subnodes vertically in stacks of 2 downwards
    if (allLeaf(subNodes)) {
      for (var i = 0; i < subNodes.length; i++) {
        subNodes[i].position = offset +
            Offset(
                i % 2 == 0
                    ? subNodes.length > i + 1 || subNodes.length == 1
                        ? 0
                        : boxSize.width / 2 + spacing.width / 2
                    : spacing.width + boxSize.width,
                (_getLevel(subNodes[i]) + i ~/ 2) *
                    (boxSize.height + spacing.height));
      }
      node.position = offset +
          Offset(
              (subNodes.length > 1 ? boxSize.width / 2 + spacing.width / 2 : 0),
              _getLevel(node) * (boxSize.height + spacing.height));
      return (subNodes.length > 1
          ? boxSize.width * 2 + spacing.width * 3
          : boxSize.width + spacing.width * 2);
    } else {
      /// if not all are leaves then draw subnodes horizontally
      double dxOff = 0;
      for (var i = 0; i < subNodes.length; i++) {
        dxOff += _calculateNP(subNodes[i],
            offset: offset + Offset(dxOff + spacing.width, 0));
      }
      double relOff = _getRelOffset(node);
      dxOff = 0;
      node.position = subNodes.length == 1
          ? Offset(subNodes.first.position.dx,
              _getLevel(node) * (boxSize.height + spacing.height))
          : offset +
              Offset(relOff / 2 - boxSize.width / 2,
                  _getLevel(node) * (boxSize.height + spacing.height));
      return relOff;
    }
  }

  /// call this function when you want to recalculate the positions of the nodes
  /// for example if you want to restore the postion after dragging the items around
  /// but don't forget to setState after calcutions
  /// this function is called automatically when you change the items list
  void calculatePosition() {
    for (Node<E> node in _nodes.where((element) => _getLevel(element) == 1)) {
      _calculateNP(node);
    }
  }

  /// returns the total size of the graph
  Offset getSize({Offset offset = const Offset(0, 0)}) {
    for (Node node in _nodes) {
      offset = Offset(
        math.max(offset.dx, node.position.dx),
        math.max(offset.dy, node.position.dy),
      );
    }
    return offset;
  }

  /// returns the distance between 2 points
  double _distance(Offset a, Offset b) {
    return math.sqrt(math.pow(a.dx - b.dx, 2) + math.pow(a.dy - b.dy, 2));
  }

  /// input: the node that we want to get the overlapping nodes with
  /// returns a list of nodes that are overlapping with the input node
  /// sorted by closest to farthest from the input node
  List<Node<E>> getOverlapping(Node<E> node) {
    List<Node<E>> overlapping = [];
    for (Node<E> n in _nodes.cast<Node<E>>()) {
      Offset offset = node.position - n.position;
      if (offset.dx.abs() < boxSize.width &&
          offset.dy.abs() < boxSize.height &&
          idProvider(node.data) != idProvider(n.data)) {
        overlapping.add(n);
      }
    }
    overlapping.sort((a, b) =>
        // TODO: use the distance function defined on the node class instead
        // a.distance(node).compareTo(b.distance(node))

        _distance(a.position, node.position)
            .compareTo(_distance(b.position, node.position)));
    return overlapping;
  }
}
