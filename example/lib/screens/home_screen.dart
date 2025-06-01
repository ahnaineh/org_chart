import 'package:flutter/material.dart';
import 'package:org_chart/org_chart.dart';

import '../models/chart_config.dart';
import '../utils/chart_utils.dart';
import '../widgets/chart_node_widget.dart';
import '../widgets/chart_options_sidebar.dart';
import '../widgets/dialogs.dart';

/// The main home screen displaying the organization chart
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final OrgChartController<Map<String, dynamic>> controller;
  // CustomInteractiveViewer controller for direct manipulation
  final CustomInteractiveViewerController _interactiveController =
      CustomInteractiveViewerController();

  // Configuration for the chart
  late ChartConfig config;
  final FocusNode focusNode = FocusNode();

  // Available colors for nodes
  final List<Color> colorOptions = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.amber,
    Colors.indigo,
    Colors.pink,
    Colors.cyan,
    Colors.brown,
    Colors.deepOrange,
  ];

  @override
  void initState() {
    super.initState();
    focusNode.addListener(() {
      setState(() {});
    });
    // Initialize with default configuration
    config = ChartConfig(); // Initialize the controller with sample data
    controller = OrgChartController<Map<String, dynamic>>(
      items: ChartUtils.nodesToMaps(ChartUtils.getSampleData()),
      idProvider: (item) => item['id'],
      toProvider: (item) => item['parent'],
      toSetter: (item, newId) => {...item, 'parent': newId},
      boxSize: const Size(180, 90),
      spacing: config.nodeSpacing,
      runSpacing: config.levelSpacing,
      leafColumns: config.leafColumnCount,
    );
  }

  @override
  void dispose() {
    focusNode.dispose();
    _interactiveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Org Chart Example'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInstructions,
            tooltip: 'Instructions',
          ),
        ],
      ),
      body: Row(
        children: [
          // Left Sidebar
          ChartOptionsSidebar(
            config: config,
            controller: controller,
            interactiveViewerController: _interactiveController,
            onConfigChanged: (newConfig) {
              // Check if leaf column count has changed
              if (config.leafColumnCount != newConfig.leafColumnCount) {
                controller.leafColumns = newConfig.leafColumnCount;
                controller.calculatePosition();
              }

              setState(() {
                config = newConfig;
              });
            },
            onAddNodePressed: _showAddNodeDialog,
            onResetLayoutPressed: () {
              controller.calculatePosition();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Layout reset')),
              );
            },
          ),

          // Main Content
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withOpacity(0.5),
                    Theme.of(context).colorScheme.surface,
                  ],
                ),
              ),
              child: _buildOrgChart(),
            ),
          ),
        ],
      ),
    );
  }

  /// Build the organization chart
  Widget _buildOrgChart() {
    return Stack(
      children: [
        OrgChart<Map<String, dynamic>>(
          controller: controller,
          viewerController: _interactiveController,
          builder: (details) => ChartNodeWidget(
            details: details,
            cornerRadius: config.cornerRadius,
          ),
          optionsBuilder: (item) => _buildOptionsMenu(item),
          onOptionSelect: _handleOptionSelect,
          isDraggable: config.isDraggable,
          enableZoom: config.enableZoom,
          cornerRadius: config.cornerRadius,
          arrowStyle: config.arrowStyle,
          duration: config.animationDuration,
          curve: config.animationCurve,
          minScale: config.minScale,
          maxScale: config.maxScale,
          // Custom interactive viewer parameters
          enableRotation: config.enableRotation,
          constrainBounds: config.constrainBounds,
          enableDoubleTapZoom: config.enableDoubleTapZoom,
          doubleTapZoomFactor: config.doubleTapZoomFactor,
          enableKeyRepeat: config.enableKeyRepeat,
          keyRepeatInitialDelay: config.keyRepeatInitialDelay,
          keyRepeatInterval: config.keyRepeatInterval,
          enableCtrlScrollToScale: config.enableCtrlScrollToScale,
          enableFling: config.enableFling, enablePan: config.enablePan,
          enableKeyboardControls: config.enableKeyboardControls,
          keyboardPanDistance: config.keyboardPanDistance,
          keyboardZoomFactor: config.keyboardZoomFactor,
          animateKeyboardTransitions: config.animateKeyboardTransitions,
          keyboardAnimationCurve: config.keyboardAnimationCurve,
          keyboardAnimationDuration: config.keyboardAnimationDuration,
          invertArrowKeyDirection: config.invertArrowKeyDirection,
          focusNode: focusNode,
          linePaint: config.getLinePaint(context),
          onDrop: (dragged, target, isTargetSubnode) {
            if (isTargetSubnode) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Cannot drop a node onto its own child')),
              );
              controller.calculatePosition();
              return;
            }

            if (dragged['parent'] == target['id']) {
              controller.calculatePosition();
              return;
            }

            setState(() {
              dragged['parent'] = target['id'];
              controller.calculatePosition();
            });
          },
        ),
        if (focusNode.hasFocus)
          IgnorePointer(
            child: Stack(
              children: [
                SizedBox.expand(
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 4,
                          blurStyle: BlurStyle.outer,
                        ),
                      ],
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.6),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.keyboard,
                          size: 16,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Focus Mode",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
      ],
    );
  }

  /// Build the context menu for nodes
  List<PopupMenuEntry<String>> _buildOptionsMenu(Map<String, dynamic> item) {
    final List<PopupMenuEntry<String>> options = [];

    // Don't allow removing the root node
    if (item['parent'] != null) {
      options.add(
        PopupMenuItem(
          value: 'remove',
          child: const ListTile(
            leading: Icon(Icons.delete_outline),
            title: Text('Remove Node'),
          ),
        ),
      );
    }

    options.addAll([
      PopupMenuItem(
        value: 'edit',
        child: const ListTile(
          leading: Icon(Icons.edit_outlined),
          title: Text('Edit Node'),
        ),
      ),
      PopupMenuItem(
        value: 'add',
        child: const ListTile(
          leading: Icon(Icons.add_circle_outline),
          title: Text('Add Child'),
        ),
      ),
      PopupMenuItem(
        value: 'color',
        child: const ListTile(
          leading: Icon(Icons.color_lens_outlined),
          title: Text('Change Color'),
        ),
      ),
    ]);

    return options;
  }

  /// Handle menu option selection
  void _handleOptionSelect(Map<String, dynamic> item, dynamic value) {
    switch (value) {
      case 'remove':
        _removeNode(item);
        break;
      case 'edit':
        _handleEditNode(item);
        break;
      case 'add':
        _addChildNode(item);
        break;
      case 'color':
        _changeNodeColor(item);
        break;
    }
  }

  /// Remove a node from the chart
  void _removeNode(Map<String, dynamic> item) {
    setState(() {
      try {
        controller.removeItem(
            item['id'], ActionOnNodeRemoval.removeDescendants);
      } catch (e) {
        _showError('Failed to remove node: ${e.toString()}');
      }
    });
  }

  /// Edit an existing node
  void _handleEditNode(Map<String, dynamic> item) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => NodeDialog(
        title: 'Edit Node',
        initialName: item['name'],
        isNewNode: false,
        availableParents: controller.items,
      ),
    );

    if (result != null && result['name'] != null && result['name'].isNotEmpty) {
      setState(() {
        item['name'] = result['name'];
      });
    }
  }

  /// Add a child node to an existing node
  void _addChildNode(Map<String, dynamic> item) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => NodeDialog(
        title: 'Add Child Node',
        initialParentId: item['id'],
        isNewNode: true,
        availableParents: controller.items,
      ),
    );

    if (result != null && result['name'] != null && result['name'].isNotEmpty) {
      final newNode = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'parent': item['id'],
        'name': result['name'],
        'color': Colors.blue,
      };

      setState(() {
        controller.addItem(newNode);
      });
    }
  }

  /// Show dialog to add a new node
  void _showAddNodeDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => NodeDialog(
        title: 'Add New Node',
        isNewNode: true,
        availableParents: controller.items,
      ),
    );

    if (result != null && result['name'] != null && result['name'].isNotEmpty) {
      final newNode = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'parent': result['parentId'],
        'name': result['name'],
        'color': Colors.blue,
      };

      setState(() {
        controller.addItem(newNode);
      });
    }
  }

  /// Change the color of a node
  void _changeNodeColor(Map<String, dynamic> item) async {
    final result = await showDialog<Color?>(
      context: context,
      builder: (context) => ColorPickerDialog(colorOptions: colorOptions),
    );

    if (result != null) {
      setState(() {
        item['color'] = result;
      });
    }
  }

  /// Show the instructions dialog
  void _showInstructions() {
    showDialog(
      context: context,
      builder: (context) => const InstructionsDialog(),
    );
  }

  /// Show an error dialog
  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
