import 'package:flutter/material.dart';
import 'package:org_chart/src/node.dart';
import 'dart:math' as math;

enum OrgChartOrientation { topToBottom, leftToRight }

enum ActionOnNodeRemoval { unlink, connectToParent, removeDescendants }

class OrgChartController<E> {
  // Private fields
  late List<Node<E>> _nodes;
  OrgChartOrientation _orientation;

  // Public properties
  Size boxSize;
  double spacing;
  double runSpacing;
  String? Function(E data) idProvider;
  String? Function(E data) toProvider;
  void Function(E data, String? newID)? toSetter;

  // Internal state management
  void Function(void Function() function)? setState;
  void Function()? centerChart;

  OrgChartOrientation get orientation => _orientation;

  @Deprecated(
      "Use `switchOrientation` instead, can't implement optional centering here.")
  set orientation(OrgChartOrientation orientation) {
    _orientation = orientation;
    calculatePosition();
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
  }) : _orientation = orientation {
    this.items = items;
  }

  // Public API methods
  List<E> get items => _nodes.map((e) => e.data).toList();

  set items(List<E> items) {
    _nodes = items.map((e) => Node(data: e)).toList();
    calculatePosition();
  }

  void switchOrientation(
      {OrgChartOrientation? orientation, bool center = true}) {
    _orientation = orientation ??
        (_orientation == OrgChartOrientation.topToBottom
            ? OrgChartOrientation.leftToRight
            : OrgChartOrientation.topToBottom);
    calculatePosition(center: center);
  }

  void removeItem(String? id, ActionOnNodeRemoval action) {
    if (action == ActionOnNodeRemoval.unlink ||
        action == ActionOnNodeRemoval.connectToParent) {
      assert(toSetter != null,
          "toSetter is not provided, you can't use this function without providing a toSetter");
    }

    final nodeToRemove =
        _nodes.firstWhere((element) => idProvider(element.data) == id);

    final subnodes =
        _nodes.where((element) => toProvider(element.data) == id).toList();

    for (Node<E> node in subnodes) {
      switch (action) {
        case ActionOnNodeRemoval.unlink:
          toSetter!(node.data, null);
          break;
        case ActionOnNodeRemoval.connectToParent:
          toSetter!(node.data, toProvider(nodeToRemove.data));
          break;
        case ActionOnNodeRemoval.removeDescendants:
          _removeNodeAndDescendants(_nodes, node);
          break;
      }
    }

    _nodes.remove(nodeToRemove);
    calculatePosition();
  }

  String get uniqueNodeId {
    int id = 0;
    while (_nodes.any((element) => idProvider(element.data) == id.toString())) {
      id++;
    }
    return id.toString();
  }

  void addItem(E item) {
    _nodes.add(Node(data: item));
    calculatePosition();
  }

  void changeNodeIndex(Node<E> node, int index) {
    _nodes.remove(node);
    _nodes.insert(index == -1 ? math.max(_nodes.length - 1, 0) : index, node);
  }

  void calculatePosition({bool center = true}) {
    double offset = 0;
    for (Node<E> node in roots) {
      offset += _calculateNodePositions(
        node,
        offset: _orientation == OrgChartOrientation.topToBottom
            ? Offset(offset, 0)
            : Offset(0, offset),
      );
    }

    setState?.call(() {});
    if (center) {
      centerChart?.call();
    }
  }

  Size getSize({Size size = const Size(0, 0)}) {
    for (Node<E> node in _nodes) {
      size = Size(
        math.max(size.width, node.position.dx),
        math.max(size.height, node.position.dy),
      );
    }
    return size + Offset(boxSize.width, boxSize.height);
  }

  List<Node<E>> getOverlapping(Node<E> node) {
    List<Node<E>> overlapping = [];
    final String nodeId = idProvider(node.data) ?? '';

    for (Node<E> n in _nodes) {
      final String nId = idProvider(n.data) ?? '';
      if (nodeId != nId) {
        Offset offset = node.position - n.position;
        if (offset.dx.abs() < boxSize.width &&
            offset.dy.abs() < boxSize.height) {
          overlapping.add(n);
        }
      }
    }

    overlapping.sort((a, b) => a
        .distance(node)
        .distanceSquared
        .compareTo(b.distance(node).distanceSquared));

    return overlapping;
  }

  // Node-related methods
  List<Node<E>> get roots =>
      _nodes.where((node) => _getLevel(node) == 1).toList();

  List<Node<E>> getSubNodes(Node<E> node) {
    final nodeId = idProvider(node.data);
    return _nodes
        .where((element) => toProvider(element.data) == nodeId)
        .toList();
  }

  bool allLeaf(List<Node<E>> nodes) {
    return nodes
        .every((element) => getSubNodes(element).isEmpty || element.hideNodes);
  }

  // Private position calculation methods
  double _calculateNodePositions(Node<E> node,
      {Offset offset = const Offset(0, 0)}) {
    return _orientation == OrgChartOrientation.topToBottom
        ? _calculatePositionsTopToBottom(node, offset: offset)
        : _calculatePositionsLeftToRight(node, offset: offset);
  }

  double _calculatePositionsTopToBottom(Node<E> node,
      {Offset offset = const Offset(0, 0)}) {
    List<Node<E>> subNodes = getSubNodes(node);

    if (allLeaf(subNodes)) {
      return _positionLeafNodesTopToBottom(node, subNodes, offset);
    } else {
      return _positionNonLeafNodesTopToBottom(node, subNodes, offset);
    }
  }

  double _calculatePositionsLeftToRight(Node<E> node,
      {Offset offset = const Offset(0, 0)}) {
    List<Node<E>> subNodes = getSubNodes(node);

    if (allLeaf(subNodes)) {
      return _positionLeafNodesLeftToRight(node, subNodes, offset);
    } else {
      return _positionNonLeafNodesLeftToRight(node, subNodes, offset);
    }
  }

  double _positionLeafNodesTopToBottom(
      Node<E> node, List<Node<E>> subNodes, Offset offset) {
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
  }

  double _positionNonLeafNodesTopToBottom(
      Node<E> node, List<Node<E>> subNodes, Offset offset) {
    double dxOff = 0;
    for (var i = 0; i < subNodes.length; i++) {
      dxOff += _calculatePositionsTopToBottom(
        subNodes[i],
        offset: offset + Offset(dxOff, 0),
      );
    }

    double relOff = _getRelativeOffset(node);

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

  double _positionLeafNodesLeftToRight(
      Node<E> node, List<Node<E>> subNodes, Offset offset) {
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

    return (subNodes.length > 1
        ? boxSize.height * 2 + spacing * 3
        : boxSize.height + spacing * 2);
  }

  double _positionNonLeafNodesLeftToRight(
      Node<E> node, List<Node<E>> subNodes, Offset offset) {
    double dyOff = 0;
    for (var i = 0; i < subNodes.length; i++) {
      dyOff += _calculatePositionsLeftToRight(
        subNodes[i],
        offset: offset + Offset(0, dyOff),
      );
    }

    double relOff = _getRelativeOffset(node);

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

    return relOff;
  }

  double _getRelativeOffset(Node<E> node) {
    return _orientation == OrgChartOrientation.topToBottom
        ? _getRelativeOffsetTopToBottom(node)
        : _getRelativeOffsetLeftToRight(node);
  }

  double _getRelativeOffsetTopToBottom(Node<E> node) {
    List<Node<E>> subNodes = getSubNodes(node);

    if (node.hideNodes || subNodes.isEmpty) {
      return boxSize.width + spacing * 2;
    }

    if (allLeaf(subNodes)) {
      return (subNodes.length > 1
          ? boxSize.width * 2 + spacing * 3
          : boxSize.width + spacing * 2);
    } else {
      double relativeOffset = 0.0;
      for (var subNode in subNodes) {
        relativeOffset += _getRelativeOffsetTopToBottom(subNode);
      }
      return relativeOffset;
    }
  }

  double _getRelativeOffsetLeftToRight(Node<E> node) {
    List<Node<E>> subNodes = getSubNodes(node);

    if (node.hideNodes || subNodes.isEmpty) {
      return boxSize.height + spacing * 2;
    }

    if (allLeaf(subNodes)) {
      return (subNodes.length > 1
          ? boxSize.height * 2 + spacing * 3
          : boxSize.height + spacing * 2);
    } else {
      double relativeOffset = 0.0;
      for (var subNode in subNodes) {
        relativeOffset += _getRelativeOffsetLeftToRight(subNode);
      }
      return relativeOffset;
    }
  }

  int _getLevel(Node<E> node) {
    int level = 1;
    Node<E>? current = node;
    String? currentToId;

    while (current != null) {
      currentToId = toProvider(current.data);
      if (currentToId == null) break;

      try {
        current = _nodes.firstWhere((n) => idProvider(n.data) == currentToId);
        level++;
      } catch (_) {
        break;
      }
    }
    return level;
  }

  /// Removes a node and all its descendants from the list of nodes
  void _removeNodeAndDescendants(List<Node<E>> nodes, Node<E> nodeToRemove) {
    Set<Node<E>> nodesToRemove = {};

    void collectDescendantNodes(Node<E> currentNode) {
      nodesToRemove.add(currentNode);

      final nodeId = idProvider(currentNode.data);
      final subnodes =
          _nodes.where((element) => toProvider(element.data) == nodeId);

      for (final node in subnodes) {
        collectDescendantNodes(node);
      }
    }

    collectDescendantNodes(nodeToRemove);
    nodes.removeWhere((node) => nodesToRemove.contains(node));
  }
}
