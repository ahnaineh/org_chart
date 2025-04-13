import 'package:flutter/material.dart';
import 'package:org_chart/org_chart.dart';
// import '../models/chart_node.dart';

/// Custom node widget builder for the organization chart
class ChartNodeWidget extends StatelessWidget {
  final NodeBuilderDetails<Map<String, dynamic>> details;
  final double cornerRadius;

  const ChartNodeWidget({
    super.key,
    required this.details,
    this.cornerRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final Color nodeColor = (details.item['color'] as Color?) ?? Colors.blue;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cornerRadius),
        side: BorderSide(
          color: nodeColor.withAlpha(100),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => details.hideNodes(),
        child: Container(
          // width: controller.boxSize.width,
          // height: controller.boxSize.height,
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: nodeColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    details.item['name'].toString().substring(0, 1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                details.item['name'],
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
