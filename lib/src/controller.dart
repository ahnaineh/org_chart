import 'package:flutter/material.dart';
import 'package:org_chart/src/node.dart';
import 'dart:math' as math;

enum OrgChartOrientation { topToBottom, leftToRight }

enum ActionOnNodeRemoval { unlink, connectToParent }

class OrgChartController<E> {
  /// The list of nodes that we want to draw. this is generated from the items list.
  late List<Node<E>> _nodes;

  /// The size of each node box. Needed to determine it here and not in the contentBuilder function
  /// because I need this value for the calculations
  Size boxSize;

  /// The spacing between each node box. Needed here for the same reason i need boxSize here.
  double spacing;
  double runSpacing;

  /// The following function is included to ease the use of custom data types
  /// whether it be a map with key 'id' or 'pk' or a custom class, just use this function to provide the ids
  /// The function that returns the id of the node.
  String? Function(E data) idProvider;

  /// The following function is included to ease the use of custom data types
  /// whether it be a map with key 'id' or 'pk' or a custom class, just use this function to provide the ids
  /// The function that returns the id of the node that the current node is pointing to.
  String? Function(E data) toProvider;

  /// Used to change the to-id of the node when using removeItem function
  /// if not provided, using removeItem will not be allowed!
  void Function(E data, String? newID)? toSetter;

  /// setState Function, hooked automatically to redraw the node positions are recalculated.
  void Function(void Function() function)? setState;

  void Function()? centerChart;

  OrgChartOrientation _orientation;
  OrgChartOrientation get orientation => _orientation;

  @Deprecated(
      "Use [`switchOrientation`] instead, can't implement optional centering here.")
  set orientation(OrgChartOrientation orientation) {
    _orientation = orientation;
    calculatePosition();
  }

  /// Switches the orientation of the chart,
  /// if orientaiton is not provided, the other orientation will be used
  /// if the current orientation is topToBottom, the new orientation will be leftToRight
  /// if the current orientation is leftToRight, the new orientation will be topToBottom
  /// if center is true, the chart will be centered after the switch
  void switchOrientation(
      {OrgChartOrientation? orientation, bool center = true}) {
    _orientation = orientation ??
        (_orientation == OrgChartOrientation.topToBottom
            ? OrgChartOrientation.leftToRight
            : OrgChartOrientation.topToBottom);
    calculatePosition();
    if (center) {
      centerChart?.call();
    }
  }

  OrgChartController({
    required List<E> items,
    this.boxSize = const Size(200, 100),
    this.spacing = 20,
    this.runSpacing = 50,
    required this.idProvider,
    required this.toProvider,
    this.toSetter,
    OrgChartOrientation orientation = OrgChartOrientation.leftToRight,
  })  : _orientation = orientation,
        super() {
    this.items = items;
  }

  /// returns the list of items showed in the graph
  /// use the remove item if you want to remove an item from the list
  List<E> get items => _nodes.map((e) => e.data).toList();

  double _calculateNPTopToBottom(
    Node<E> node, {
    Offset offset = const Offset(0, 0),
  }) {
    List<Node<E>> subNodes = getSubNodes(node);

    if (allLeaf(subNodes)) {
      for (var i = 0; i < subNodes.length; i++) {
        subNodes[i].position = offset +
            Offset(
              i % 2 == 0
                  ? subNodes.length > i + 1 || subNodes.length == 1
                      ? 0
                      : boxSize.width / 2 + spacing / 2
                  : spacing + boxSize.width,
              ((_getLevel(subNodes[i]) - 1) + i ~/ 2) *
                  (boxSize.height + runSpacing),
            );
      }
      node.position = offset +
          Offset(
            (subNodes.length > 1 ? boxSize.width / 2 + spacing / 2 : 0),
            (_getLevel(node) - 1) * (boxSize.height + runSpacing),
          );
      return (subNodes.length > 1
          ? boxSize.width * 2 + spacing * 3
          : boxSize.width + spacing * 2);
    } else {
      double dxOff = 0;
      for (var i = 0; i < subNodes.length; i++) {
        dxOff += _calculateNPTopToBottom(
          subNodes[i],
          offset: offset + Offset(dxOff, 0),
        );
      }
      double relOff = _getRelOffset(node);
      dxOff = 0;

      node.position = subNodes.length == 1
          ? Offset(
              subNodes.first.position.dx,
              (_getLevel(node) - 1) * (boxSize.height + runSpacing),
            )
          : offset +
              Offset(
                relOff / 2 - boxSize.width / 2 - spacing,
                (_getLevel(node) - 1) * (boxSize.height + runSpacing),
              );
      return relOff;
    }
  }

  double _calculateNPLeftToRight(Node<E> node,
      {Offset offset = const Offset(0, 0)}) {
    double returnValue = 0;
    List<Node<E>> subNodes = getSubNodes(node);

    /// if all the sub nodes are leaves, then draw subnodes vertically in stacks of 2 downwards
    if (allLeaf(subNodes)) {
      for (var i = 0; i < subNodes.length; i++) {
        subNodes[i].position = offset +
            Offset(
              ((_getLevel(subNodes[i]) - 1) + i ~/ 2) *
                  (boxSize.width + runSpacing),
              i % 2 == 0
                  ? subNodes.length > i + 1 || subNodes.length == 1
                      ? 0
                      : boxSize.height / 2 + spacing / 2
                  : spacing + boxSize.height,
            );
      }
      node.position = offset +
          Offset(
            (_getLevel(node) - 1) * (boxSize.width + runSpacing),
            (subNodes.length > 1 ? boxSize.height / 2 + spacing / 2 : 0),
          );
      returnValue = (subNodes.length > 1
          ? boxSize.height * 2 + spacing * 3

          /// multiplier used to change the distance between the group of nodes
          : boxSize.height + spacing * 2);
    } else {
      /// if not all are leaves then draw subnodes horizontally
      double dyOff = 0;
      for (var i = 0; i < subNodes.length; i++) {
        dyOff += _calculateNPLeftToRight(
          subNodes[i],
          offset: offset + Offset(0, dyOff),
        );
      }
      double relOff = _getRelOffset(node);

      node.position = subNodes.length == 1
          ? Offset(
              (_getLevel(node) - 1) * (boxSize.width + runSpacing),
              subNodes.first.position.dy,
            )
          : offset +
              Offset(
                (_getLevel(node) - 1) * (boxSize.width + runSpacing),
                relOff / 2 - boxSize.height / 2 - spacing,
              );
      returnValue = relOff;
    }
    return returnValue;
  }

  /// to add an item
  set items(List<E> items) {
    _nodes = items.map((e) => Node(data: e)).toList();
    calculatePosition();
  }

  /// to remove an item from the list
  void removeItem(id, ActionOnNodeRemoval action) {
    assert(toSetter != null,
        "toSetter is not provided, you can't use this function without providing an toSetter");
    List subnodes =
        _nodes.where((element) => toProvider(element.data) == id).toList();
    switch (action) {
      case ActionOnNodeRemoval.unlink:
        for (Node<E> node in subnodes) {
          toSetter!(node.data, null);
        }
        break;
      case ActionOnNodeRemoval.connectToParent:
        for (Node<E> node in subnodes) {
          toSetter!(node.data, toProvider(node.data));
        }
        break;
    }
    _nodes.removeWhere((element) => idProvider(element.data) == id);
    calculatePosition();
  }

  /// to generate a unique id for an item
  /// this is used when you want to add an item to the list
  /// and you don't want to set an id
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
  List<Node<E>> get roots =>
      _nodes.where((node) => _getLevel(node) == 1).toList();

  /// changes the index of the node in the list, if index is -1 then it will be moved to the end of the list
  /// this is used on drag start to move the dragged node to the end of the list so that it will be drawn on top
  void changeNodeIndex(Node<E> node, index) {
    _nodes.remove(node);
    _nodes.insert(index == -1 ? math.max(_nodes.length - 1, 0) : index, node);
  }

  /// return the relative X offset of the node
  double _getRelOffset(Node<E> node) {
    switch (_orientation) {
      case OrgChartOrientation.topToBottom:
        return _getRelOffsetTopToBottom(node);
      case OrgChartOrientation.leftToRight:
        return _getRelOffsetLeftToRight(node);
    }
  }

  double _getRelOffsetTopToBottom(Node<E> node) {
    List<Node<E>> subNodes = getSubNodes(node);
    if (node.hideNodes || subNodes.isEmpty) {
      return boxSize.width + spacing * 2;
    }

    double relativeOffset = 0.0;

    if (allLeaf(subNodes)) {
      return (subNodes.length > 1
          ? boxSize.width * 2 + spacing * 3
          : boxSize.width + spacing * 2);
    } else {
      for (var i = 0; i < subNodes.length; i++) {
        relativeOffset += _getRelOffsetTopToBottom(subNodes[i]);
      }
    }
    return relativeOffset;
  }

  double _getRelOffsetLeftToRight(Node<E> node) {
    List<Node<E>> subNodes = getSubNodes(node);

    if (node.hideNodes || subNodes.isEmpty) {
      return boxSize.height + spacing * 2;
    }

    double relativeOffset = 0.0;
    if (allLeaf(subNodes)) {
      return (subNodes.length > 1
          ? boxSize.height * 2 + spacing * 3
          : boxSize.height + spacing * 2);
    } else {
      for (var i = 0; i < subNodes.length; i++) {
        relativeOffset += _getRelOffsetLeftToRight(subNodes[i]);
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
    switch (_orientation) {
      case OrgChartOrientation.topToBottom:
        return _calculateNPTopToBottom(node, offset: offset);
      case OrgChartOrientation.leftToRight:
        return _calculateNPLeftToRight(node, offset: offset);
    }
  }

  /// call this function when you want to recalculate the positions of the nodes
  /// for example if you want to restore the postion after dragging the items around
  /// but don't forget to setState after calcutions
  /// this function is called automatically when you change the items list
  void calculatePosition({bool center = true}) {
    double offset = 0;
    for (Node<E> node in roots) {
      offset += _calculateNP(
        node,
        offset: _orientation == OrgChartOrientation.topToBottom
            ? Offset(offset, 0)
            : Offset(0, offset),
      );
      setState?.call(() {});
      if (center) {
        centerChart?.call();
      }
    }
  }

  /// returns the total size of the graph
  Offset getSize({Offset offset = const Offset(0, 0)}) {
    for (Node node in roots) {
      offset = Offset(
        math.max(offset.dx, node.position.dx),
        math.max(offset.dy, node.position.dy),
      );
      if(!node.hideNodes) {
        offset = getSize(offset: offset);
      }
    }
    return offset + Offset(boxSize.width, boxSize.height);
  }

  /// input: the node that we want to get the overlapping nodes with
  /// returns a list of nodes that are overlapping with the input node
  /// sorted by closest to farthest from the input node
  List<Node<E>> getOverlapping(Node<E> node) {
    List<Node<E>> overlapping = [];
    for (Node<E> n in _nodes) {
      Offset offset = node.position - n.position;
      if (offset.dx.abs() < boxSize.width &&
          offset.dy.abs() < boxSize.height &&
          idProvider(node.data) != idProvider(n.data)) {
        overlapping.add(n);
      }
    }
    overlapping.sort((a, b) => a
        .distance(node)
        .distanceSquared
        .compareTo(b.distance(node).distanceSquared));

    return overlapping;
  }
}
