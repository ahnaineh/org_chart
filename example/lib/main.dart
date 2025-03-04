import 'package:flutter/material.dart';
import 'package:org_chart/org_chart.dart';
import 'widgets/org_chart_node.dart';
import 'models/node_data.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Organization Chart Example',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const Example(),
    );
  }
}

class Example extends StatefulWidget {
  const Example({super.key});

  @override
  State<Example> createState() => _ExampleState();
}

class _ExampleState extends State<Example> {
  late final OrgChartController<NodeData> orgChartController;

  @override
  void initState() {
    super.initState();
    orgChartController = OrgChartController<NodeData>(
      boxSize: const Size(150, 100),
      items: _initialNodes,
      idProvider: (data) => data.id,
      toProvider: (data) => data.parentId,
      toSetter: _updateNodeParent,
    );
  }

  List<NodeData> get _initialNodes => [
        NodeData(id: '0', text: 'Main Block'),
        NodeData(id: '1', text: 'Block 2', parentId: '0'),
        NodeData(id: '2', text: 'Block 3', parentId: '0'),
        NodeData(id: '3', text: 'Block 4', parentId: '1'),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          DecoratedBox(
            decoration: _buildBackgroundGradient(),
            child: Stack(
              children: [
                Center(child: _buildOrgChart()),
                const _InfoOverlay(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildOrientationButton(),
    );
  }

  Widget _buildOrgChart() {
    return OrgChart<NodeData>(
      controller: orgChartController,
      arrowStyle: DashedGraphArrow(pattern: [20, 10, 5, 10]),
      cornerRadius: 10,
      isDraggable: true,
      linePaint: _buildArrowPaint(),
      builder: (details) => OrgChartNode(
        details: details,
        onAddNode: () => _handleAddNode(details.item.id),
        onEditText: () => _handleEditText(details.item),
        onToggleNodes: details.hideNodes,
      ),
      optionsBuilder: _buildOptionsMenu,
      onOptionSelect: _handleOptionSelect,
      onDrop: _handleNodeDrop,
    );
  }

  Widget _buildOrientationButton() {
    return FloatingActionButton.extended(
      label: const Text('Change Orientation'),
      icon: const Icon(Icons.rotate_90_degrees_ccw),
      onPressed: () => orgChartController.switchOrientation(),
    );
  }

  BoxDecoration _buildBackgroundGradient() {
    return const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ),
    );
  }

  Paint _buildArrowPaint() {
    return Paint()
      ..color = Colors.grey.shade600
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
  }

  List<PopupMenuEntry<String>> _buildOptionsMenu(NodeData item) {
    // Don't allow removing the root node
    if (item.parentId == null) return const [];

    return [
      const PopupMenuItem(
        value: 'remove',
        child: ListTile(
          leading: Icon(Icons.remove_circle_outline),
          title: Text('Remove Node'),
        ),
      ),
      const PopupMenuItem(
        value: 'edit',
        child: ListTile(
          leading: Icon(Icons.edit),
          title: Text('Edit Node'),
        ),
      )
    ];
  }

  void _handleOptionSelect(NodeData item, dynamic value) {
    if (value == 'remove') {
      _removeNode(item);
    } else if (value == 'edit') {
      _handleEditText(item);
    }
  }

  void _removeNode(NodeData item) {
    try {
      orgChartController.removeItem(item.id, ActionOnNodeRemoval.unlink);
    } catch (e) {
      _showError('Failed to remove node: ${e.toString()}');
    }
  }

  void _updateNodeParent(NodeData data, String? newParentId) {
    data.parentId = newParentId;
  }

  void _handleAddNode(String parentId) {
    try {
      final newNode = NodeData(
        id: orgChartController.uniqueNodeId,
        text: 'New Block',
        parentId: parentId,
      );
      orgChartController.addItem(newNode);
    } catch (e) {
      _showError('Failed to add node: ${e.toString()}');
    }
  }

  Future<void> _handleEditText(NodeData item) async {
    try {
      final newText = await _showTextEditDialog(item);
      if (newText == null) return;

      final index = orgChartController.items.indexOf(item);
      if (index == -1) return;
      setState(() {
        item.text = newText;
      });
    } catch (e) {
      _showError('Failed to edit node text: ${e.toString()}');
    }
  }

  void _handleNodeDrop(
      NodeData dragged, NodeData target, bool isTargetSubnode) {
    try {
      if (isTargetSubnode) {
        _showError('Cannot drop a node onto its own child');
        orgChartController.calculatePosition();
        return;
      }

      if (dragged.parentId == target.id) {
        orgChartController.calculatePosition();
        return;
      }
      dragged.parentId = target.id;
      orgChartController.calculatePosition();
    } catch (e) {
      _showError('Failed to move node: ${e.toString()}');
      orgChartController.calculatePosition();
    }
  }

  Future<String?> _showTextEditDialog(NodeData item) {
    return showDialog<String>(
      context: context,
      builder: (context) => _EditNodeDialog(initialText: item.text),
    );
  }

  void _showError(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _InfoOverlay extends StatelessWidget {
  const _InfoOverlay();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Positioned(
      bottom: 20,
      left: 20,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Instructions:', style: textTheme.titleSmall),
              const SizedBox(height: 8),
              ...[
                'Tap to add a child node',
                'Double tap to edit text',
                'Drag to rearrange nodes',
                'Right click/long press to remove',
                'Drag in empty space to pan',
                'Pinch to zoom'
              ].map(
                (text) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $text', style: textTheme.bodySmall),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditNodeDialog extends StatefulWidget {
  final String initialText;

  const _EditNodeDialog({required this.initialText});

  @override
  State<_EditNodeDialog> createState() => _EditNodeDialogState();
}

class _EditNodeDialogState extends State<_EditNodeDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Node Text'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Node Text',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
