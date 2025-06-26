import 'package:flutter/material.dart';
import 'package:org_chart/src/common/node.dart';
import '../../base/base_controller.dart';
import '../org_chart_controller.dart';

/// Mixin for node positioning utilities for OrgChartController
mixin NodePositioningMixin<E> {
  List<Node<E>> get nodes;
  List<Node<E>> get roots;
  GraphOrientation get orientation;
  Size get boxSize;
  double get spacing;
  double get runSpacing;
  void Function(void Function() function)? get setState;
  void Function()? get centerGraph;
  int getLevel(Node<E> node);
  bool allLeaf(List<Node<E>> nodes);
  List<Node<E>> getSubNodes(Node<E> node);

  /// Calculates the positions of all nodes in the chart
  void calculatePosition({bool center = true}) {
    double offset = 0;
    for (Node<E> node in roots) {
      offset += _calculateNodePositions(
        node,
        offset: orientation == GraphOrientation.topToBottom
            ? Offset(offset, 0)
            : Offset(0, offset),
      );
    }

    setState?.call(() {});
    if (center) {
      centerGraph?.call();
    }
  }

  /// Returns the size of the chart
  Size getSize({Size size = const Size(0, 0)}) {
    for (Node<E> root in roots) {
      size = _calculateMaxSize(root, size);
    }
    return size + Offset(boxSize.width, boxSize.height);
  }

  /// Recursively calculates the maximum size occupied by the chart
  Size _calculateMaxSize(Node<E> node, Size currentSize) {
    Size updatedSize = Size(
      currentSize.width > node.position.dx
          ? currentSize.width
          : node.position.dx,
      currentSize.height > node.position.dy
          ? currentSize.height
          : node.position.dy,
    );
    if (!node.hideNodes) {
      List<Node<E>> children = getSubNodes(node);
      for (Node<E> child in children) {
        updatedSize = _calculateMaxSize(child, updatedSize);
      }
    }
    return updatedSize;
  }

  /// Private method to calculate node positions
  double _calculateNodePositions(Node<E> node,
      {Offset offset = const Offset(0, 0)}) {
    return orientation == GraphOrientation.topToBottom
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
    if (subNodes.isEmpty) {
      node.position = offset +
          Offset(
            0,
            (getLevel(node) - 1) * (boxSize.height + runSpacing),
          );
      return boxSize.width + spacing;
    }
    int leafColumns = 4;
    if (this is OrgChartController<E>) {
      leafColumns = (this as OrgChartController<E>).leafColumns;
    }
    int effectiveColumns =
        subNodes.length < leafColumns ? subNodes.length : leafColumns;
    for (var i = 0; i < subNodes.length; i++) {
      int row = i ~/ effectiveColumns;
      int col = i % effectiveColumns;
      subNodes[i].position = offset +
          Offset(
            col * (boxSize.width + spacing),
            (getLevel(subNodes[i]) - 1 + row) * (boxSize.height + runSpacing),
          );
    }
    int itemsInLastRow = subNodes.length % effectiveColumns == 0
        ? effectiveColumns
        : subNodes.length % effectiveColumns;
    double lastRowWidth =
        itemsInLastRow * boxSize.width + (itemsInLastRow - 1) * spacing;
    double fullRowWidth =
        effectiveColumns * boxSize.width + (effectiveColumns - 1) * spacing;
    double maxRowWidth =
        fullRowWidth > lastRowWidth ? fullRowWidth : lastRowWidth;
    node.position = offset +
        Offset(
          (maxRowWidth - boxSize.width) / 2,
          (getLevel(node) - 1) * (boxSize.height + runSpacing),
        );
    return maxRowWidth + spacing;
  }

  double _positionNonLeafNodesTopToBottom(
      Node<E> node, List<Node<E>> subNodes, Offset offset) {
    if (subNodes.isEmpty || node.hideNodes) {
      node.position = offset +
          Offset(
            0,
            (getLevel(node) - 1) * (boxSize.height + runSpacing),
          );
      return boxSize.width + spacing;
    }
    double totalWidth = 0;
    for (var i = 0; i < subNodes.length; i++) {
      double nodeWidth = _calculatePositionsTopToBottom(
        subNodes[i],
        offset: offset + Offset(totalWidth, 0),
      );
      totalWidth += nodeWidth;
    }
    if (subNodes.length == 1) {
      node.position = Offset(
        subNodes.first.position.dx,
        (getLevel(node) - 1) * (boxSize.height + runSpacing),
      );
    } else {
      double leftmostX = subNodes.first.position.dx;
      double rightmostX = subNodes.last.position.dx + boxSize.width;
      double centerX = (leftmostX + rightmostX) / 2 - boxSize.width / 2;
      node.position = Offset(
        centerX,
        (getLevel(node) - 1) * (boxSize.height + runSpacing),
      );
    }
    return totalWidth;
  }

  double _positionLeafNodesLeftToRight(
      Node<E> node, List<Node<E>> subNodes, Offset offset) {
    if (subNodes.isEmpty) {
      node.position = offset +
          Offset(
            (getLevel(node) - 1) * (boxSize.width + runSpacing),
            0,
          );
      return boxSize.height + spacing;
    }
    int leafColumns = 4;
    if (this is OrgChartController<E>) {
      leafColumns = (this as OrgChartController<E>).leafColumns;
    }
    int effectiveColumns =
        subNodes.length < leafColumns ? subNodes.length : leafColumns;
    for (var i = 0; i < subNodes.length; i++) {
      int col = i ~/ effectiveColumns;
      int row = i % effectiveColumns;
      subNodes[i].position = offset +
          Offset(
            (getLevel(subNodes[i]) - 1 + col) * (boxSize.width + runSpacing),
            row * (boxSize.height + spacing),
          );
    }
    int itemsInLastCol = subNodes.length % effectiveColumns == 0
        ? effectiveColumns
        : subNodes.length % effectiveColumns;
    double lastColHeight =
        itemsInLastCol * boxSize.height + (itemsInLastCol - 1) * spacing;
    double fullColHeight =
        effectiveColumns * boxSize.height + (effectiveColumns - 1) * spacing;
    double maxColHeight =
        fullColHeight > lastColHeight ? fullColHeight : lastColHeight;
    node.position = offset +
        Offset(
          (getLevel(node) - 1) * (boxSize.width + runSpacing),
          (maxColHeight - boxSize.height) / 2,
        );
    return maxColHeight + spacing;
  }

  double _positionNonLeafNodesLeftToRight(
      Node<E> node, List<Node<E>> subNodes, Offset offset) {
    if (subNodes.isEmpty || node.hideNodes) {
      node.position = offset +
          Offset(
            (getLevel(node) - 1) * (boxSize.width + runSpacing),
            0,
          );
      return boxSize.height + spacing;
    }
    double totalHeight = 0;
    for (var i = 0; i < subNodes.length; i++) {
      double nodeHeight = _calculatePositionsLeftToRight(
        subNodes[i],
        offset: offset + Offset(0, totalHeight),
      );
      totalHeight += nodeHeight;
    }
    if (subNodes.length == 1) {
      node.position = Offset(
        (getLevel(node) - 1) * (boxSize.width + runSpacing),
        subNodes.first.position.dy,
      );
    } else {
      double topmostY = subNodes.first.position.dy;
      double bottommostY = subNodes.last.position.dy + boxSize.height;
      double centerY = (topmostY + bottommostY) / 2 - boxSize.height / 2;
      node.position = Offset(
        (getLevel(node) - 1) * (boxSize.width + runSpacing),
        centerY,
      );
    }
    return totalHeight;
  }
}
