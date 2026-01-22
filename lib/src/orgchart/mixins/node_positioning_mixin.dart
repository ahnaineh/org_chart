import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:org_chart/src/common/node.dart';
import '../../base/base_controller.dart';
import '../org_chart_controller.dart';
import '../org_chart_constants.dart';

/// Mixin for node positioning utilities for OrgChartController
mixin NodePositioningMixin<E> {
  List<Node<E>> get nodes;
  List<Node<E>> get roots;
  GraphOrientation get orientation;
  double get spacing;
  double get runSpacing;
  void requestLayout({bool center});
  void Function(void Function() function)? get setState;
  void Function()? get centerGraph;
  int getLevel(Node<E> node);
  bool allLeaf(List<Node<E>> nodes);
  List<Node<E>> getSubNodes(Node<E> node);

  final Map<int, double> _levelSizes = {};
  final Map<int, double> _levelOffsets = {};

  /// Marks layout as required. Actual layout happens in the render object.
  void calculatePosition({bool center = true}) {
    requestLayout(center: center);
  }

  /// Performs layout using measured node sizes.
  void performLayout() {
    _buildLevelMetrics();

    double offset = 0;
    for (Node<E> node in roots) {
      offset += _calculateNodePositions(
        node,
        offset: orientation == GraphOrientation.topToBottom
            ? Offset(offset, 0)
            : Offset(0, offset),
      );
    }
  }

  double _levelOffsetFor(int level) => _levelOffsets[level] ?? 0;

  void _buildLevelMetrics() {
    _levelSizes.clear();
    _levelOffsets.clear();

    int maxLevel = 0;
    for (final node in nodes) {
      final int level = getLevel(node);
      final double mainSize = orientation == GraphOrientation.topToBottom
          ? node.size.height
          : node.size.width;
      final double current = _levelSizes[level] ?? 0;
      if (mainSize > current) {
        _levelSizes[level] = mainSize;
      }
      if (level > maxLevel) {
        maxLevel = level;
      }
    }

    double offset = 0;
    for (int level = 1; level <= maxLevel; level++) {
      _levelOffsets[level] = offset;
      offset += (_levelSizes[level] ?? 0) + runSpacing;
    }
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
    final double nodeWidth = node.size.width;
    final int nodeLevel = getLevel(node);
    final double nodeY = _levelOffsetFor(nodeLevel);

    if (subNodes.isEmpty || node.hideNodes) {
      node.position = offset + Offset(0, nodeY);
      return nodeWidth + spacing;
    }

    int leafColumns = OrgChartConstants.defaultLeafColumns;
    if (this is OrgChartController<E>) {
      leafColumns = (this as OrgChartController<E>).leafColumns;
    }

    final int columnCount =
        subNodes.length < leafColumns ? subNodes.length : leafColumns;
    final int rowCount = (subNodes.length / columnCount).ceil();

    final List<double> columnWidths = List<double>.filled(columnCount, 0);
    final List<double> rowHeights = List<double>.filled(rowCount, 0);

    for (var i = 0; i < subNodes.length; i++) {
      final int row = i ~/ columnCount;
      final int col = i % columnCount;
      final Node<E> child = subNodes[i];
      columnWidths[col] = math.max(columnWidths[col], child.size.width);
      rowHeights[row] = math.max(rowHeights[row], child.size.height);
    }

    final List<double> columnOffsets = List<double>.filled(columnCount, 0);
    double runningX = 0;
    for (int col = 0; col < columnCount; col++) {
      columnOffsets[col] = runningX;
      runningX += columnWidths[col] + (col == columnCount - 1 ? 0 : spacing);
    }

    final List<double> rowOffsets = List<double>.filled(rowCount, 0);
    double runningY = 0;
    for (int row = 0; row < rowCount; row++) {
      rowOffsets[row] = runningY;
      runningY += rowHeights[row] + (row == rowCount - 1 ? 0 : runSpacing);
    }

    final double gridWidth =
        columnWidths.fold(0.0, (sum, width) => sum + width) +
            spacing * math.max(0, columnCount - 1);
    final double baseY = _levelOffsetFor(getLevel(subNodes.first));

    for (var i = 0; i < subNodes.length; i++) {
      final int row = i ~/ columnCount;
      final int col = i % columnCount;
      subNodes[i].position = offset +
          Offset(
            columnOffsets[col],
            baseY + rowOffsets[row],
          );
    }

    node.position = offset +
        Offset(
          (gridWidth - nodeWidth) / 2,
          nodeY,
        );

    return gridWidth + spacing;
  }

  double _positionNonLeafNodesTopToBottom(
      Node<E> node, List<Node<E>> subNodes, Offset offset) {
    final double nodeWidth = node.size.width;
    final int nodeLevel = getLevel(node);
    final double nodeY = _levelOffsetFor(nodeLevel);

    if (subNodes.isEmpty || node.hideNodes) {
      node.position = offset + Offset(0, nodeY);
      return nodeWidth + spacing;
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
        nodeY,
      );
    } else {
      double leftmostX = subNodes.first.position.dx;
      final Node<E> last = subNodes.last;
      double rightmostX = last.position.dx + last.size.width;
      double centerX = (leftmostX + rightmostX) / 2 - nodeWidth / 2;
      node.position = Offset(
        centerX,
        nodeY,
      );
    }
    return totalWidth;
  }

  double _positionLeafNodesLeftToRight(
      Node<E> node, List<Node<E>> subNodes, Offset offset) {
    final double nodeHeight = node.size.height;
    final int nodeLevel = getLevel(node);
    final double nodeX = _levelOffsetFor(nodeLevel);

    if (subNodes.isEmpty || node.hideNodes) {
      node.position = offset + Offset(nodeX, 0);
      return nodeHeight + spacing;
    }

    int leafColumns = OrgChartConstants.defaultLeafColumns;
    if (this is OrgChartController<E>) {
      leafColumns = (this as OrgChartController<E>).leafColumns;
    }

    final int rowCount =
        subNodes.length < leafColumns ? subNodes.length : leafColumns;
    final int columnCount = (subNodes.length / rowCount).ceil();

    final List<double> columnWidths = List<double>.filled(columnCount, 0);
    final List<double> rowHeights = List<double>.filled(rowCount, 0);

    for (var i = 0; i < subNodes.length; i++) {
      final int col = i ~/ rowCount;
      final int row = i % rowCount;
      final Node<E> child = subNodes[i];
      columnWidths[col] = math.max(columnWidths[col], child.size.width);
      rowHeights[row] = math.max(rowHeights[row], child.size.height);
    }

    final List<double> columnOffsets = List<double>.filled(columnCount, 0);
    double runningX = 0;
    for (int col = 0; col < columnCount; col++) {
      columnOffsets[col] = runningX;
      runningX += columnWidths[col] + (col == columnCount - 1 ? 0 : runSpacing);
    }

    final List<double> rowOffsets = List<double>.filled(rowCount, 0);
    double runningY = 0;
    for (int row = 0; row < rowCount; row++) {
      rowOffsets[row] = runningY;
      runningY += rowHeights[row] + (row == rowCount - 1 ? 0 : spacing);
    }

    final double gridHeight =
        rowHeights.fold(0.0, (sum, height) => sum + height) +
            spacing * math.max(0, rowCount - 1);
    final double baseX = _levelOffsetFor(getLevel(subNodes.first));

    for (var i = 0; i < subNodes.length; i++) {
      final int col = i ~/ rowCount;
      final int row = i % rowCount;
      subNodes[i].position = offset +
          Offset(
            baseX + columnOffsets[col],
            rowOffsets[row],
          );
    }

    node.position = offset +
        Offset(
          nodeX,
          (gridHeight - nodeHeight) / 2,
        );

    return gridHeight + spacing;
  }

  double _positionNonLeafNodesLeftToRight(
      Node<E> node, List<Node<E>> subNodes, Offset offset) {
    final double nodeHeight = node.size.height;
    final int nodeLevel = getLevel(node);
    final double nodeX = _levelOffsetFor(nodeLevel);

    if (subNodes.isEmpty || node.hideNodes) {
      node.position = offset + Offset(nodeX, 0);
      return nodeHeight + spacing;
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
        nodeX,
        subNodes.first.position.dy,
      );
    } else {
      double topmostY = subNodes.first.position.dy;
      final Node<E> last = subNodes.last;
      double bottommostY = last.position.dy + last.size.height;
      double centerY = (topmostY + bottommostY) / 2 - nodeHeight / 2;
      node.position = Offset(
        nodeX,
        centerY,
      );
    }
    return totalHeight;
  }
}
