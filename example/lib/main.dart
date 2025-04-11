import 'package:flutter/material.dart';
import 'package:org_chart/org_chart.dart';
import 'package:org_chart_example/models/family_member.dart';
import 'package:org_chart_example/widgets/genogram_node.dart';
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
      title: 'Family Genogram Example',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
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
  late final GenogramController<FamilyMember> genogramController;
  bool showOrgChart = false;

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

    genogramController = GenogramController<FamilyMember>(
      boxSize: const Size(150, 150),
      spacing: 30, // Reduced from 100 to bring siblings closer together
      runSpacing: 60, // Reduced from 150 to bring children closer to parents
      items: _sampleFamilyMembers,
      idProvider: (data) => data.id,
      fatherProvider: (data) => data.fatherId,
      motherProvider: (data) => data.motherId,
      spousesProvider: (data) => data.spouses,
      // Add the new genogram-specific providers - fixing nullable return types
      genderProvider: (data) => data.gender,
      // isDeceasedProvider: (data) => data.isDeceased,
      // relationshipTypesProvider: (data) =>
      //     data.relationshipTypes as Map<String, RelationshipType>?,
      // nameProvider: (data) => data.name, // Add name provider
    );
  }

  List<NodeData> get _initialNodes => [
        NodeData(id: '0', text: 'Main Block'),
        NodeData(id: '1', text: 'Block 2', parentId: '0'),
        NodeData(id: '2', text: 'Block 3', parentId: '0'),
        NodeData(id: '3', text: 'Block 4', parentId: '1'),
      ];

  List<FamilyMember> get _sampleFamilyMembers => [
        // First generation - Grandparents
        // FamilyMember(
        //   id: 'ewtrcae21',
        //   name: 'Sawsaw',
        //   gender: 1,
        //   spouses: [],
        //   // relationshipTypes: {'gm1': RelationshipType.married},
        //   isDeceased: true,
        //   fatherId: 'f1',
        //   motherId:'m1',
        //   // birthDate: DateTime(1920),
        //   // deathDate: DateTime(1990),
        // ),
        // FamilyMember(
        //   id: 'ewtdre21',
        //   name: 'Sawsaw',
        //   gender: 1,
        //   spouses: [],
        //   // relationshipTypes: {'gm1': RelationshipType.married},
        //   isDeceased: true,
        //   fatherId: 'f1',
        //   motherId:'m1',
        //   // birthDate: DateTime(1920),
        //   // deathDate: DateTime(1990),
        // ),
        // FamilyMember(
        //   id: 'ewtre21',
        //   name: 'Sawsaw',
        //   gender: 1,
        //   spouses: [],
        //   // relationshipTypes: {'gm1': RelationshipType.married},
        //   isDeceased: true,
        //   fatherId: 'f1',
        //   motherId:'m1',
        //   // birthDate: DateTime(1920),
        //   // deathDate: DateTime(1990),
        // ),
        // FamilyMember(
        //   id: 'ewdtre',
        //   name: 'Sawsaw',
        //   gender: 1,
        //   spouses: [],
        //   // relationshipTypes: {'gm1': RelationshipType.married},
        //   isDeceased: true,
        //   fatherId: 'f1',
        //   motherId:'m1',
        //   // birthDate: DateTime(1920),
        //   // deathDate: DateTime(1990),
        // ),
        // FamilyMember(
        //   id: 'ewtre',
        //   name: 'Sawsaw',
        //   gender: 1,
        //   spouses: [],
        //   // relationshipTypes: {'gm1': RelationshipType.married},
        //   isDeceased: true,
        //   fatherId: 'f1',
        //   motherId:'m1',
        //   // birthDate: DateTime(1920),
        //   // deathDate: DateTime(1990),
        // ),
        FamilyMember(
          id: 'gf1',
          name: 'Robert Smith',
          gender: 0,
          spouses: ['gm1'],
          // relationshipTypes: {'gm1': RelationshipType.married},
          isDeceased: true,
          birthDate: DateTime(1920),
          deathDate: DateTime(1990),
        ),
        FamilyMember(
          id: 'gm1',
          name: 'Mary Smith',
          gender: 1,
          spouses: ['gf1'],
          // relationshipTypes: {'gf1': RelationshipType.married},
          isDeceased: true,
          birthDate: DateTime(1925),
          deathDate: DateTime(1995),
        ),

        // First generation - Other side
        FamilyMember(
          id: 'gf2',
          name: 'James Johnson',
          gender: 0,
          spouses: ['gm2', 'gm2b'],
          // relationshipTypes: {
          //   'gm2': RelationshipType.divorced,
          //   'gm2b': RelationshipType.married,
          // },
          isDeceased: true,
          birthDate: DateTime(1918),
          deathDate: DateTime(1985),
        ),
        FamilyMember(
          id: 'gm2',
          name: 'Emma Johnson',
          gender: 1,
          spouses: ['gf2'],
          // relationshipTypes: {'gf2': RelationshipType.divorced},
          birthDate: DateTime(1922),
          deathDate: DateTime(2000),
          isDeceased: true,
        ),
        FamilyMember(
          id: 'gm2b',
          name: 'Helen Johnson',
          gender: 1,
          spouses: ['gf2'],
          // relationshipTypes: {'gf2': RelationshipType.married},
          birthDate: DateTime(1930),
          isDeceased: false,
        ),

        // Second generation - Parents
        FamilyMember(
          id: 'f1',
          name: 'John Smith',
          gender: 0,
          fatherId: 'gf1',
          motherId: 'gm1',
          spouses: ['m1', 'm2', 'm3', 'm4'],
          // relationshipTypes: {'m1': RelationshipType.married},
          birthDate: DateTime(1950),
          isDeceased: false,
        ),
        FamilyMember(
          id: 'm1',
          name: 'Sarah Smith',
          gender: 1,
          fatherId: 'gf2',
          motherId: 'gm2',
          spouses: ['f1'],
          // relationshipTypes: {'f1': RelationshipType.married},
          birthDate: DateTime(1952),
          isDeceased: false,
        ),
        FamilyMember(
          id: 'm2',
          name: 'Sarah Smith',
          gender: 1,
          // fatherId: 'gf2',
          // motherId: 'gm2',
          spouses: ['f1'],
          // relationshipTypes: {'f1': RelationshipType.married},
          birthDate: DateTime(1952),
          isDeceased: false,
        ),
        FamilyMember(
          id: 'm3',
          name: 'Sarah Smith',
          gender: 1,
          // fatherId: 'gf2',
          // motherId: 'gm2',
          spouses: ['f1'],
          // relationshipTypes: {'f1': RelationshipType.married},
          birthDate: DateTime(1952),
          isDeceased: false,
        ),
        FamilyMember(
          id: 'm4',
          name: 'Sarah Smith',
          gender: 1,
          // fatherId: 'gf2',
          // motherId: 'gm2',
          spouses: ['f1'],
          // relationshipTypes: {'f1': RelationshipType.married},
          birthDate: DateTime(1952),
          isDeceased: false,
        ),

        // Uncle with multiple marriages
        FamilyMember(
          id: 'u2241',
          name: 'Thomas Smith',
          gender: 0,
          fatherId: 'gf1',
          motherId: 'gm1',
          // spouses: ['a1', 'a2'],
          // relationshipTypes: {
          //   'a1': RelationshipType.divorced,
          //   'a2': RelationshipType.married
          // },
          birthDate: DateTime(1955),
          isDeceased: false,
        ),
        FamilyMember(
          id: 'u201',
          name: 'Thomas Smith',
          gender: 0,
          fatherId: 'gf1',
          motherId: 'gm1',
          // spouses: ['a1', 'a2'],
          // relationshipTypes: {
          //   'a1': RelationshipType.divorced,
          //   'a2': RelationshipType.married
          // },
          birthDate: DateTime(1955),
          isDeceased: false,
        ),
        FamilyMember(
          id: 'u2901',
          name: 'Thomas Smith',
          gender: 0,
          fatherId: 'gf1',
          motherId: 'gm1',
          // spouses: ['a1', 'a2'],
          // relationshipTypes: {
          //   'a1': RelationshipType.divorced,
          //   'a2': RelationshipType.married
          // },
          birthDate: DateTime(1955),
          isDeceased: false,
        ),
        FamilyMember(
          id: 'u-21',
          name: 'Thomas Smith',
          gender: 0,
          fatherId: 'gf1',
          motherId: 'gm1',
          // spouses: ['a1', 'a2'],
          // relationshipTypes: {
          //   'a1': RelationshipType.divorced,
          //   'a2': RelationshipType.married
          // },
          birthDate: DateTime(1955),
          isDeceased: false,
        ),
        FamilyMember(
          id: 'u219=',
          name: 'Thomas Smith',
          gender: 0,
          fatherId: 'gf1',
          motherId: 'gm1',
          // spouses: ['a1', 'a2'],
          // relationshipTypes: {
          //   'a1': RelationshipType.divorced,
          //   'a2': RelationshipType.married
          // },
          birthDate: DateTime(1955),
          isDeceased: false,
        ),
        FamilyMember(
          id: 'u21',
          name: 'Thomas Smith',
          gender: 0,
          fatherId: 'gf1',
          motherId: 'gm1',
          // spouses: ['a1', 'a2'],
          // relationshipTypes: {
          //   'a1': RelationshipType.divorced,
          //   'a2': RelationshipType.married
          // },
          birthDate: DateTime(1955),
          isDeceased: false,
        ),
        FamilyMember(
          id: 'u212',
          name: 'Thomas Smith',
          gender: 0,
          fatherId: 'gf1',
          motherId: 'gm1',
          // spouses: ['a1', 'a2'],
          // relationshipTypes: {
          //   'a1': RelationshipType.divorced,
          //   'a2': RelationshipType.married
          // },
          birthDate: DateTime(1955),
          isDeceased: false,
        ),
        // Uncle with multiple marriages
        FamilyMember(
          id: 'u1',
          name: 'Thomas Smith',
          gender: 0,
          fatherId: 'gf1',
          motherId: 'gm1',
          spouses: ['a1', 'a2'],
          // relationshipTypes: {
          //   'a1': RelationshipType.divorced,
          //   'a2': RelationshipType.married
          // },
          birthDate: DateTime(1955),
          isDeceased: false,
        ),
        FamilyMember(
          id: 'a1',
          name: 'Patricia',
          gender: 1,
          spouses: ['u1'],
          // relationshipTypes: {'u1': RelationshipType.divorced},
          birthDate: DateTime(1958),
          isDeceased: false,
        ),
        FamilyMember(
          id: 'a2',
          name: 'Jennifer',
          gender: 1,
          spouses: ['u1'],
          // relationshipTypes: {'u1': RelationshipType.married},
          birthDate: DateTime(1960),
          isDeceased: false,
        ),

        // Aunt from second marriage
        FamilyMember(
          id: 'a3',
          name: 'Barbara Johnson',
          gender: 1,
          fatherId: 'gf2',
          motherId: 'gm2b',
          birthDate: DateTime(1962),
          isDeceased: false,
        ),

        // Third generation - Siblings including twins
        FamilyMember(
          id: 'c1',
          name: 'Michael Smith',
          gender: 0,
          fatherId: 'f1',
          motherId: 'm1',
          birthDate: DateTime(1975),
          isDeceased: false,
          spouses: ['p1'],
          // relationshipTypes: {'p1': RelationshipType.married},
        ),
        FamilyMember(
          id: 'c2',
          name: 'David Smith',
          gender: 0,
          fatherId: 'f1',
          motherId: 'm1',
          birthDate: DateTime(1980),
          isDeceased: false,
          // birthType: BirthType.identical,
          // ,
        ),
        FamilyMember(
          id: 'c3',
          name: 'Daniel Smith',
          gender: 0,
          fatherId: 'f1',
          motherId: 'm1',
          birthDate: DateTime(1980),
          isDeceased: false,
          // birthType: BirthType.identical,
        
        ),
        FamilyMember(
          id: 'c4',
          name: 'Emily Smith',
          gender: 1,
          fatherId: 'f1',
          motherId: 'm1',
          birthDate: DateTime(1985),
          isDeceased: false,
        ),

        // Cousins from uncle's first marriage
        FamilyMember(
          id: 'c5',
          name: 'Jessica',
          gender: 1,
          fatherId: 'u1',
          motherId: 'a1',
          birthDate: DateTime(1978),
          isDeceased: false,
        ),

        // Cousins from uncle's second marriage - Fraternal twins
        FamilyMember(
          id: 'c6',
          name: 'Matthew',
          gender: 0,
          fatherId: 'u1',
          motherId: 'a2',
          birthDate: DateTime(1988),
          isDeceased: false,
          // birthType: BirthType.fraternal,
          // ,
        ),
        FamilyMember(
          id: 'c7',
          name: 'Olivia',
          gender: 1,
          fatherId: 'u1',
          motherId: 'a2',
          birthDate: DateTime(1988),
          isDeceased: false,
          // birthType: BirthType.fraternal,
          // ,
        ),

        // Fourth generation
        FamilyMember(
          id: 'p1',
          name: 'Amanda Smith',
          gender: 1,
          spouses: ['c1'],
          // relationshipTypes: {'c1': RelationshipType.married},
          birthDate: DateTime(1978),
          isDeceased: false,
        ),
        FamilyMember(
          id: 'gc1',
          name: 'Sophia Smith',
          gender: 1,
          fatherId: 'c1',
          motherId: 'p1',
          birthDate: DateTime(2005),
          isDeceased: false,
        ),
        FamilyMember(
          id: 'gc2',
          name: 'William Smith',
          gender: 0,
          fatherId: 'c1',
          motherId: 'p1',
          birthDate: DateTime(2008),
          isDeceased: false,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(showOrgChart ? 'Organization Chart' : 'Family Genogram'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfo(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          DecoratedBox(
            decoration: _buildBackgroundGradient(),
            child: Center(
              child: _buildChart(),
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            label: Text(showOrgChart ? 'Show Genogram' : 'Show Org Chart'),
            icon: const Icon(Icons.swap_horiz),
            onPressed: () => setState(() => showOrgChart = !showOrgChart),
          ),
          const SizedBox(width: 8),
          FloatingActionButton.extended(
            label: const Text('Change Orientation'),
            icon: const Icon(Icons.rotate_90_degrees_ccw),
            onPressed: () => 
            showOrgChart
                ? 
                orgChartController.switchOrientation()
                : genogramController.switchOrientation(),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    if (showOrgChart) {
      return OrgChart<NodeData>(
        controller: orgChartController,
        arrowStyle: DashedGraphArrow(pattern: [20, 10, 5, 10]),
        cornerRadius: 10,
        isDraggable: true,
        linePaint: _buildArrowPaint(),
        builder: (details) => OrgChartNode(
          details: details,
          onAddNode: () => _handleAddNode(details.item.id),
          onToggleNodes: details.hideNodes,
        ),
        optionsBuilder: _buildOptionsMenu,
        onOptionSelect: _handleOptionSelect,
        onDrop: _handleNodeDrop,
      );
    } else {
      return Genogram<FamilyMember>(
        controller: genogramController,
        cornerRadius: 15,
        isDraggable: true,
        linePaint: _buildGenogramLinePaint(),
        builder: (details) => GenogramNode(
          details: details,
          onToggleNodes: details.hideNodes,
        ),
      );
    }
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
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
  }

  Paint _buildGenogramLinePaint() {
    return Paint()
      ..color = Colors.grey.shade800
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
  }

  void _updateNodeParent(NodeData data, String? newParentId) {
    data.parentId = newParentId;
  }

  List<PopupMenuEntry<String>> _buildOptionsMenu(NodeData item) {
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

  void _handleNodeDrop(
      NodeData dragged, NodeData target, bool isTargetSubnode) {
    try {
      if (isTargetSubnode) {
        _showError('Cannot drop a node onto its own child');
        orgChartController.calculatePosition(center: false);
        return;
      }

      if (dragged.parentId == target.id) {
        orgChartController.calculatePosition(center: false);
        return;
      }
      dragged.parentId = target.id;
      orgChartController.calculatePosition(center: false);
    } catch (e) {
      _showError('Failed to move node: ${e.toString()}');
      orgChartController.calculatePosition(center: false);
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

  void _showInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(showOrgChart ? 'Organization Chart' : 'Family Genogram'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              showOrgChart
                  ? 'This demonstrates a basic organizational chart.'
                  : 'This genogram demonstrates:',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (!showOrgChart) ...[
              const SizedBox(height: 12),
              ...[
                'Multiple generations',
                'Gender-specific shapes (square/circle)',
                'Deceased indicators (diagonal line)',
                'Marriage and divorce relationships',
                'Identical and fraternal twins',
                'Multiple marriages',
                'Proper parent-child connections'
              ].map((text) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(child: Text(text)),
                      ],
                    ),
                  )),
              const SizedBox(height: 12),
              Text(
                'Interactions:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              ...[
                'Drag to pan the view',
                'Pinch to zoom',
                'Tap +/- to collapse branches',
                'Switch orientation with the button'
              ].map((text) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(child: Text(text)),
                      ],
                    ),
                  )),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
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
