import 'package:flutter/material.dart';
import 'package:org_chart/src/node_builder_details.dart';
import '../models/node_data.dart';

class OrgChartNode extends StatelessWidget {
  static const double _nodePadding = 8.0;
  static const double _defaultFontSize = 16.0;
  static const double _spacing = 4.0;

  final NodeBuilderDetails<NodeData> details;
  final VoidCallback onAddNode;
  final VoidCallback onEditText;
  final void Function(bool?) onToggleNodes;

  const OrgChartNode({
    super.key,
    required this.details,
    required this.onAddNode,
    required this.onEditText,
    required this.onToggleNodes,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildNodeCard(context),
        const SizedBox(height: _spacing),
        if (_hasChildren) _buildToggleButton(context),
      ],
    );
  }

  Widget _buildNodeCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: 'Node: ${details.item.text}',
      hint: details.isBeingDragged
          ? 'Being dragged'
          : details.isOverlapped
              ? 'Target for drop'
              : 'Long press to edit, single tap to add child',
      child: Card(
        elevation: details.isBeingDragged ? 8 : 4,
        color: _getNodeColor(colorScheme),
        child: InkWell(
          onTap: onAddNode,
          // onDoubleTap: onEditText,
          child: Padding(
            padding: const EdgeInsets.all(_nodePadding),
            child: Center(
              child: Text(
                details.item.text,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: _defaultFontSize,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton(BuildContext context) {
    final theme = Theme.of(context);
    return FilledButton.tonal(
      onPressed: () => onToggleNodes(!details.nodesHidden),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            details.nodesHidden
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            details.nodesHidden ? 'Show Children' : 'Hide Children',
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  Color _getNodeColor(ColorScheme colorScheme) {
    if (details.isBeingDragged) {
      return colorScheme.primaryContainer;
    }
    if (details.isOverlapped) {
      return colorScheme.errorContainer;
    }
    return colorScheme.surface;
  }

  bool get _hasChildren => !_isRoot && details.level > 1;
  bool get _isRoot => details.level == 1;
}
