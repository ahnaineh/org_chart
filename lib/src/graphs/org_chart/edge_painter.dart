import 'package:flutter/material.dart';

import 'package:org_chart/src/common/edge_painter.dart';
import 'package:org_chart/src/common/node.dart';
import 'package:org_chart/src/controllers/org_chart_controller.dart';

/// Edge painter specific to organizational charts
class OrgChartEdgePainter<E> extends BaseEdgePainter<E> {
  /// The org chart controller
  final OrgChartController<E> chartController;

  OrgChartEdgePainter({
    required this.chartController,
    required super.linePaint,
    super.cornerRadius,
    required super.arrowStyle,
  }) : super(
          controller: chartController,
        );

  @override
  void drawNodeConnections(Node<E> node, Canvas canvas) {
    List<Node<E>> subNodes = chartController.getSubNodes(node);

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

      drawConnection(canvas, start, end, controller.boxSize,
          type: connectionType);
    }
  }

  /// Get the center position of a node
  Offset getNodeCenter(Node<E> node) {
    return node.position +
        Offset(chartController.boxSize.width / 2,
            chartController.boxSize.height / 2);
  }

  /// Check if a node is a leaf node (no visible children)
  bool isLeafNode(Node<E> node) {
    return node.hideNodes || chartController.getSubNodes(node).isEmpty;
  }

  bool allLeaf(List<Node<E>> nodes) {
    return nodes.every((node) => isLeafNode(node));
  }
}
