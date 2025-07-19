import 'package:flutter/material.dart';
import 'package:org_chart/src/base/base_controller.dart';

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
    LineEndingType lineEndingType = LineEndingType.arrow,
  }) : utils = EdgePainterUtils(
          linePaint: linePaint,
          cornerRadius: cornerRadius,
          arrowStyle: arrowStyle,
          lineEndingType: lineEndingType,
        );

  @override
  bool shouldRepaint(covariant OrgChartEdgePainter<E> oldDelegate) {
    // Only repaint if the controller or paint properties have changed
    return oldDelegate.controller != controller ||
        oldDelegate.utils.linePaint != utils.linePaint ||
        oldDelegate.utils.cornerRadius != utils.cornerRadius ||
        oldDelegate.utils.arrowStyle != utils.arrowStyle ||
        oldDelegate.utils.lineEndingType != utils.lineEndingType;
  }

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
    // Check if ALL children are leaf nodes
    bool allChildrenAreLeaves = subNodes.every((child) => isLeafNode(child));
    
    // For each subnode, draw the appropriate connection
    for (int i = 0; i < subNodes.length; i++) {
      var subNode = subNodes[i];
      Offset start;
      Offset end;

      // Calculate start and end offsets based on orientation and whether children are leaves
      if (controller.orientation == GraphOrientation.leftToRight) {
        // For left-to-right: start from right side of parent
        start = getNodeCenter(node) + Offset(controller.boxSize.width / 2, 0);
        
        if (allChildrenAreLeaves) {
          // For leaf nodes: end at the center of the child (side approach will be handled by simpleLeafNode)
          end = getNodeCenter(subNode);
        } else {
          // For non-leaf nodes: end at left side of child
          end = getNodeCenter(subNode) - Offset(controller.boxSize.width / 2, 0);
        }
      } else {
        // For top-to-bottom: start from bottom of parent
        start = getNodeCenter(node) + Offset(0, controller.boxSize.height / 2);
        
        if (allChildrenAreLeaves) {
          // For leaf nodes: end at the center of the child (side approach will be handled by simpleLeafNode)
          end = getNodeCenter(subNode);
        } else {
          // For non-leaf nodes: end at top of child
          end = getNodeCenter(subNode) - Offset(0, controller.boxSize.height / 2);
        }
      }

      // Use simpleLeafNode connection type if all children are leaves
      ConnectionType connectionType = allChildrenAreLeaves 
          ? ConnectionType.simpleLeafNode 
          : ConnectionType.adaptive;
      
      // Use appropriate connection type for leaf vs non-leaf nodes
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
}
