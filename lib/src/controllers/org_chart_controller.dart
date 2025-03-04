import 'package:flutter/material.dart';

import 'package:org_chart/src/common/node.dart';
import 'package:org_chart/src/controllers/base_controller.dart';

/// The orientation of the organizational chart
enum OrgChartOrientation { topToBottom, leftToRight }

/// Defines actions to take when removing nodes from the org chart
enum ActionOnNodeRemoval { unlink, connectToParent }

/// Controller specifically for organizational charts
class OrgChartController<E> extends BaseGraphController<E> {
  // Private fields
  OrgChartOrientation _orientation;

  /// Get the current orientation of the chart
  OrgChartOrientation get orientation => _orientation;

  OrgChartController({
    required List<E> items,
    Size boxSize = const Size(200, 100),
    double spacing = 20,
    double runSpacing = 50,
    required String? Function(E data) idProvider,
    required String? Function(E data) toProvider,
    void Function(E data, String? newID)? toSetter,
    OrgChartOrientation orientation = OrgChartOrientation.leftToRight,
  })  : _orientation = orientation,
        super(
          items: items,
          boxSize: boxSize,
          spacing: spacing,
          runSpacing: runSpacing,
          idProvider: idProvider,
          toProvider: toProvider,
          toSetter: toSetter,
        );

  /// Switch the orientation of the chart
  void switchOrientation(
      {OrgChartOrientation? orientation, bool center = true}) {
    _orientation = orientation ??
        (_orientation == OrgChartOrientation.topToBottom
            ? OrgChartOrientation.leftToRight
            : OrgChartOrientation.topToBottom);
    calculatePosition(center: center);
  }

  /// Remove an item from the chart
  void removeItem(String? id, ActionOnNodeRemoval action) {
    assert(toSetter != null,
        "toSetter is not provided, you can't use this function without providing a toSetter");

    final subnodes =
        super.roots.where((element) => toProvider(element.data) == id).toList();

    for (Node<E> node in subnodes) {
      switch (action) {
        case ActionOnNodeRemoval.unlink:
          toSetter!(node.data, null);
          break;
        case ActionOnNodeRemoval.connectToParent:
          toSetter!(node.data, toProvider(node.data));
          break;
      }
    }

    items = items.where((element) => idProvider(element) != id).toList();
  }

  @override
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
      centerGraph?.call();
    }
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

  // Position calculations for leaf nodes (nodes without hidden children)
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
            ((getLevel(subNodes[i]) - 1) + i ~/ 2) *
                (boxSize.height + runSpacing),
          );
    }

    node.position = offset +
        Offset(
          (subNodes.length > 1 ? boxSize.width / 2 + spacing / 2 : 0),
          (getLevel(node) - 1) * (boxSize.height + runSpacing),
        );

    return (subNodes.length > 1
        ? boxSize.width * 2 + spacing * 3
        : boxSize.width + spacing * 2);
  }

  // Position calculations for non-leaf nodes (nodes with visible children)
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
            (getLevel(node) - 1) * (boxSize.height + runSpacing),
          )
        : offset +
            Offset(
              relOff / 2 - boxSize.width / 2 - spacing,
              (getLevel(node) - 1) * (boxSize.height + runSpacing),
            );

    return relOff;
  }

  // Position calculations for leaf nodes in left-to-right orientation
  double _positionLeafNodesLeftToRight(
      Node<E> node, List<Node<E>> subNodes, Offset offset) {
    for (var i = 0; i < subNodes.length; i++) {
      subNodes[i].position = offset +
          Offset(
            ((getLevel(subNodes[i]) - 1) + i ~/ 2) *
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
          (getLevel(node) - 1) * (boxSize.width + runSpacing),
          (subNodes.length > 1 ? boxSize.height / 2 + spacing / 2 : 0),
        );

    return (subNodes.length > 1
        ? boxSize.height * 2 + spacing * 3
        : boxSize.height + spacing * 2);
  }

  // Position calculations for non-leaf nodes in left-to-right orientation
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
            (getLevel(node) - 1) * (boxSize.width + runSpacing),
            subNodes.first.position.dy,
          )
        : offset +
            Offset(
              (getLevel(node) - 1) * (boxSize.width + runSpacing),
              relOff / 2 - boxSize.height / 2 - spacing,
            );

    return relOff;
  }

  // Calculate relative offsets between nodes
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
}
