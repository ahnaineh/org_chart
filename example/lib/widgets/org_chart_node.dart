import 'package:flutter/material.dart';
import 'package:org_chart/org_chart.dart';
import '../models/node_data.dart';

class OrgChartNode extends StatelessWidget {
  final NodeBuilderDetails<NodeData> details;
  final VoidCallback onAddNode;
  final VoidCallback onEditText;
  final void Function(bool? hide) onToggleNodes;

  const OrgChartNode({
    super.key,
    required this.details,
    required this.onAddNode,
    required this.onEditText,
    required this.onToggleNodes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRoot = details.item.parentId == null;

    return Card(
      elevation: details.isBeingDragged ? 8 : 2,
      color: _getCardColor(theme, isRoot),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: details.isOverlapped
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onAddNode,
        onDoubleTap: onEditText,
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                details.item.text,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isRoot ? Colors.white : null,
                ),
              ),
              if (!isRoot) ...[
                const SizedBox(height: 4),
                _buildCollapseButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollapseButton() {
    return IconButton(
      iconSize: 20,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      icon: Icon(
        details.nodesHidden
            ? Icons.add_circle_outline
            : Icons.remove_circle_outline,
      ),
      onPressed: () => onToggleNodes(null),
    );
  }

  Color _getCardColor(ThemeData theme, bool isRoot) {
    if (details.isBeingDragged) {
      return theme.colorScheme.primaryContainer;
    }
    if (isRoot) {
      return theme.colorScheme.primary;
    }
    return theme.cardColor;
  }
}
