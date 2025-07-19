import 'package:flutter/material.dart';

import 'package:org_chart/src/base/edge_painter_utils.dart';
import 'package:org_chart/src/common/node.dart';
import 'package:org_chart/src/orgchart/org_chart_controller.dart';

/// Edge painter specific to organizational charts
// extends BaseEdgePainter<E>
class OrgChartEdgePainter<E> extends CustomPainter {
  /// The org chart controller
  final OrgChartController<E> controller;
  final EdgePainterUtils utils;

  OrgChartEdgePainter({
    required this.controller,
    required Paint linePaint,
    double cornerRadius = 15,
    required GraphArrowStyle arrowStyle,
  }) : utils = EdgePainterUtils(
          linePaint: linePaint,
          cornerRadius: cornerRadius,
          arrowStyle: arrowStyle,
        );

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  /// Draw arrows for all root nodes
  @override
  void paint(Canvas canvas, Size size) {
    for (var node in controller.roots) {
      drawNodeConnections(node, canvas);
    }
  }

  void drawNodeConnections(Node<E> node, Canvas canvas) {
    List<Node<E>> subNodes = controller.getSubNodes(node);

    if (node.hideNodes == false && subNodes.isNotEmpty) {
      drawNodeSubnodeConnections(node, subNodes, canvas);

      // Recursively process child nodes that have their own children
      for (var subNode in subNodes) {
        if (!isLeafNode(subNode)) {
          drawNodeConnections(subNode, canvas);
        }
      }
    }
  }

  /// Draw connections from a node to all its subnodes
  void drawNodeSubnodeConnections(
      Node<E> node, List<Node<E>> subNodes, Canvas canvas) {
    // Check if all subnodes are leaves
    bool allLeavesNodes = allLeaf(subNodes);

    // For each subnode, draw the appropriate connection
    for (int i = 0; i < subNodes.length; i++) {
      var subNode = subNodes[i];
      Offset start = getNodeCenter(node);
      Offset end = getNodeCenter(subNode);

      ConnectionType connectionType;

      if (allLeavesNodes) {
        // For leaf nodes, always use simpleLeafNode connection type
        // which now implements our four-segment approach
        connectionType = ConnectionType.simpleLeafNode;
      } else {
        // For non-leaf nodes, use adaptive connection type
        connectionType = ConnectionType.adaptive;
      }

      utils.drawConnection(
          canvas, start, end, controller.boxSize, controller.orientation,
          type: connectionType);
    }
  }

  /// Get the center position of a node
  Offset getNodeCenter(Node<E> node) {
    return node.position +
        Offset(controller.boxSize.width / 2, controller.boxSize.height / 2);
  }

  /// Check if a node is a leaf node (no visible children)
  bool isLeafNode(Node<E> node) {
    return node.hideNodes || controller.getSubNodes(node).isEmpty;
  }

  bool allLeaf(List<Node<E>> nodes) {
    return nodes.every((node) => isLeafNode(node));
  }
}
