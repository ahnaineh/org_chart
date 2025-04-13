import 'package:flutter/material.dart';
import '../models/chart_node.dart';

/// Helper class containing utility methods for the org chart
class ChartUtils {
  /// Get the name of a curve
  static String getCurveName(Curve curve) {
    if (curve == Curves.easeInOut) return 'easeInOut';
    if (curve == Curves.easeIn) return 'easeIn';
    if (curve == Curves.easeOut) return 'easeOut';
    if (curve == Curves.linear) return 'linear';
    if (curve == Curves.elasticIn) return 'elasticIn';
    if (curve == Curves.elasticOut) return 'elasticOut';
    if (curve == Curves.bounceIn) return 'bounceIn';
    if (curve == Curves.bounceOut) return 'bounceOut';
    return 'linear';
  }

  /// Get a curve from its name
  static Curve getCurveFromName(String name) {
    switch (name) {
      case 'easeInOut':
        return Curves.easeInOut;
      case 'easeIn':
        return Curves.easeIn;
      case 'easeOut':
        return Curves.easeOut;
      case 'linear':
        return Curves.linear;
      case 'elasticIn':
        return Curves.elasticIn;
      case 'elasticOut':
        return Curves.elasticOut;
      case 'bounceIn':
        return Curves.bounceIn;
      case 'bounceOut':
        return Curves.bounceOut;
      default:
        return Curves.linear;
    }
  }

  /// Get initial sample data for the org chart
  static List<ChartNode> getSampleData() {
    return [
      ChartNode(id: '1', parent: null, name: 'CEO', color: Colors.blue),
      ChartNode(id: '2', parent: '1', name: 'CTO', color: Colors.green),
      ChartNode(id: '3', parent: '1', name: 'CFO', color: Colors.orange),
      ChartNode(
          id: '4', parent: '2', name: 'Dev Team Lead', color: Colors.purple),
      ChartNode(id: '5', parent: '2', name: 'QA Lead', color: Colors.teal),
      ChartNode(id: '6', parent: '3', name: 'Accountant', color: Colors.amber),
      ChartNode(id: '7', parent: '4', name: 'Senior Dev', color: Colors.indigo),
      ChartNode(id: '8', parent: '4', name: 'Junior Dev', color: Colors.pink),
    ];
  }

  /// Convert list of chart nodes to map format needed by OrgChart controller
  static List<Map<String, dynamic>> nodesToMaps(List<ChartNode> nodes) {
    return nodes.map((node) => node.toMap()).toList();
  }

  /// Convert list of maps from OrgChart controller to ChartNode objects
  static List<ChartNode> mapsToNodes(List<Map<String, dynamic>> maps) {
    return maps.map((map) => ChartNode.fromMap(map)).toList();
  }
}
