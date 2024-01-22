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
  /// The function that returns the id of the node.
  /// This is a fun
  String? Function(E data) idProvider;
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

  List<E> get items => _nodes.map((e) => e.data).toList();


  set items(List<E> items) {
    _nodes = items.map((e) => Node(data: e)).toList();
    calculatePosition();
  }

  void removeItem(id) {
    _nodes.removeWhere((element) => idProvider(element.data) == id);
    calculatePosition();
  }

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

  List<Node<E>> get roots {
    return _nodes
        .where((node) => _nodes
            .where(
                (element) => idProvider(element.data) == toProvider(node.data))
            .isEmpty)
        .toList();
  }

  void changeNodeIndex(Node<E> node, index) {
    _nodes.remove(node);
    _nodes.insert(index == -1 ? math.max(_nodes.length - 1, 0) : index, node);
  }

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

  allLeaf(List<Node<E>> nodes) {
    return nodes
        .every((element) => getSubNodes(element).isEmpty || element.hideNodes);
  }

  List<Node<E>> getSubNodes(Node<E> node) {
    return _nodes
        .where((element) => toProvider(element.data) == idProvider(node.data))
        .toList();
  }

  _calculateNP(Node<E> node, {Offset offset = const Offset(0, 0)}) {
    List<Node<E>> subNodes = getSubNodes(node);

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

  void calculatePosition() {
    for (Node<E> node in _nodes.where((element) => _getLevel(element) == 1)) {
      _calculateNP(node);
    }
  }

  getSize({Offset offset = const Offset(0, 0)}) {
    for (Node node in _nodes) {
      offset = Offset(
        math.max(offset.dx, node.position.dx),
        math.max(offset.dy, node.position.dy),
      );
    }
    return offset;
  }

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
    return overlapping;
  }
}
