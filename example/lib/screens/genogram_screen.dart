import 'package:flutter/material.dart';
import 'package:org_chart/org_chart.dart';

import '../models/family_member.dart';
import '../utils/genogram_utils.dart';
import '../widgets/genogram_node.dart';

/// The screen displaying the family genogram
class GenogramScreen extends StatefulWidget {
  const GenogramScreen({super.key});

  @override
  State<GenogramScreen> createState() => _GenogramScreenState();
}

class _GenogramScreenState extends State<GenogramScreen> {
  late final GenogramController<FamilyMember> controller;
  final CustomInteractiveViewerController _interactiveController =
      CustomInteractiveViewerController();
  final FocusNode focusNode = FocusNode();

  // Sample family members and relationships
  late List<FamilyMember> _familyMembers;
  String? _selectedId;
  Set<String> _lineageIds = {};

  @override
  void initState() {
    super.initState();
    focusNode.addListener(() {
      setState(() {});
    });

    // Initialize sample data
    _familyMembers = GenogramUtils.getSampleFamilyDataWithStatuses();

    // Initialize controller
    controller = GenogramController<FamilyMember>(
      items: _familyMembers,
      idProvider: (item) => item.id,
      fatherProvider: (data) => data.fatherId,
      motherProvider: (data) => data.motherId,
      genderProvider: (data) => data.gender,
      spousesProvider: (data) => data.spouses,
      boxSize: const Size(150, 150),
      spacing: 30,
      spouseSpacing: 80,
      runSpacing: 80,
    );
  }

  void _toggleSelection(FamilyMember member) {
    setState(() {
      if (_selectedId == member.id) {
        _selectedId = null;
        _lineageIds = {};
      } else {
        _selectedId = member.id;
        _lineageIds = _collectLineageRelations(member);
      }
    });
  }

  void _clearSelection() {
    if (_selectedId == null) return;
    setState(() {
      _selectedId = null;
      _lineageIds = {};
    });
  }

  Set<String> _collectLineageRelations(FamilyMember member) {
    final Map<String, FamilyMember> byId = {
      for (final node in controller.nodes) node.data.id: node.data
    };
    final Map<String, List<FamilyMember>> childrenByParent = {};

    for (final node in controller.nodes) {
      final FamilyMember data = node.data;
      if (data.fatherId != null) {
        childrenByParent.putIfAbsent(data.fatherId!, () => []).add(data);
      }
      if (data.motherId != null) {
        childrenByParent.putIfAbsent(data.motherId!, () => []).add(data);
      }
    }

    final Set<String> related = {member.id};
    final List<String> ancestorQueue = [member.id];

    while (ancestorQueue.isNotEmpty) {
      final String currentId = ancestorQueue.removeLast();
      final FamilyMember? current = byId[currentId];
      if (current == null) continue;

      final List<String?> parents = [current.fatherId, current.motherId];
      for (final parentId in parents) {
        if (parentId == null || related.contains(parentId)) continue;
        related.add(parentId);
        ancestorQueue.add(parentId);
      }
    }

    final List<String> descendantQueue = [member.id];
    while (descendantQueue.isNotEmpty) {
      final String currentId = descendantQueue.removeLast();
      final List<FamilyMember> children =
          childrenByParent[currentId] ?? const [];
      for (final child in children) {
        if (related.contains(child.id)) continue;
        related.add(child.id);
        descendantQueue.add(child.id);
      }
    }

    return related;
  }

  bool _isRelated(FamilyMember member) {
    if (_selectedId == null) return true;
    return _lineageIds.contains(member.id);
  }

  EdgeStyle _edgeStyleProvider(EdgeInfo<FamilyMember> edge) {
    if (_selectedId == null) return const EdgeStyle();
    final String sourceId = controller.idProvider(edge.source.data);
    final String targetId = controller.idProvider(edge.target.data);
    final bool isRelated =
        _lineageIds.contains(sourceId) && _lineageIds.contains(targetId);
    return EdgeStyle(opacity: isRelated ? 1.0 : 0.08);
  }

  Widget? _edgeLabelBuilder(EdgeInfo<FamilyMember> edge) {
    if (edge.type != EdgeType.genogramMarriage) null;
    final MarriageStatus status =
        edge.data['marriageStatus'] as MarriageStatus? ??
            MarriageStatus.married;
    final String label =
        status == MarriageStatus.divorced ? 'Divorced' : 'Married';
    return _edgeLabelChip(label);
  }

  Widget _edgeLabelChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
      ),
    );
  }

  MarriageStatus _getMarriageStatus(FamilyMember person, FamilyMember spouse) {
    final String? status = _getRelationshipStatus(person, spouse.id) ??
        _getRelationshipStatus(spouse, person.id);
    if (status == 'divorced') {
      return MarriageStatus.divorced;
    }
    return MarriageStatus.married;
  }

  String? _getRelationshipStatus(FamilyMember person, String spouseId) {
    final relationships = person.extraData['relationships'];
    if (relationships is! Map<String, dynamic>) return null;
    final entry = relationships[spouseId];
    if (entry is! Map) return null;
    final status = entry['status'];
    return status is String ? status : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Genogram Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInstructions,
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar for genogram options
          Expanded(
            flex: 1,
            child: Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Genogram Controls',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      controller.calculatePosition();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Layout reset')),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset Layout'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _clearSelection,
                    icon: const Icon(Icons.filter_alt_off),
                    label: const Text('Clear Highlight'),
                  ),
                  const Divider(height: 32),
                  Text(
                    'Legend',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _buildLegendItem('Male', Colors.blue.shade50, true),
                  const SizedBox(height: 8),
                  _buildLegendItem('Female', Colors.pink.shade50, false),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 2,
                        color: Colors.black,
                      ),
                      const SizedBox(width: 8),
                      const Text('Marriage'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CustomPaint(
                          painter: DivorceLinePainter(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Divorce'),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
            ),
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
                        .withValues(alpha: 0.5),
                    Theme.of(context).colorScheme.surface,
                  ],
                ),
              ),
              child: _buildGenogram(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isSquare) {
    final shape = isSquare ? BoxShape.rectangle : BoxShape.circle;

    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            shape: shape,
            border: Border.all(color: Colors.grey.shade500),
          ),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  Widget _buildGenogram() {
    return Genogram<FamilyMember>(
      controller: controller,
      viewerController: _interactiveController,
      edgeStyleProvider: _selectedId == null ? null : _edgeStyleProvider,
      edgeLabelBuilder: _edgeLabelBuilder,
      edgeLabelConfig: const EdgeLabelConfig(
        avoidOverlaps: true,
        anchor: EdgeLabelAnchor.center,
      ),
      marriageStatusProvider: _getMarriageStatus,
      builder: (details) {
        final bool dimmed = !_isRelated(details.item);
        return AnimatedOpacity(
          opacity: dimmed ? 0.2 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: GestureDetector(
            onTap: () => _toggleSelection(details.item),
            child: GenogramNode(
              details: details,
              onToggleNodes: (hide) {
                if (hide != null) {
                  controller.calculatePosition();
                }
              },
            ),
          ),
        );
      },
      edgeConfig: GenogramEdgeConfig(
          childStrokeWidth: 3,
          marriageAnchorDistance: 40,
          childSingleParentColor: Colors.grey,
          childSingleParentStrokeWidth: 5.0,
          marriageColors: [
            Colors.greenAccent,
            Colors.lightGreen,
            Colors.lightGreenAccent,
          ],
          defaultMarriageStyle: MarriageStyle(
            lineStyle: MarriageLineStyle(
              color: Colors.black,
              strokeWidth: 5.0,
            ),
          ),
          divorcedMarriageStyle: MarriageStyle(
            lineStyle: MarriageLineStyle(
              color: Colors.black,
              strokeWidth: 5.0,
            ),
            decorator: const DivorceDecorator(),
          )),
      isDraggable: true,
      interactionConfig: const InteractionConfig(
        enableRotation: false,
        constrainBounds: true,
        // enablePan: true,
        // scrollMode: ScrollMode.drag,
      ),
      zoomConfig: const ZoomConfig(
        enableZoom: true,
        minScale: 0.4,
        maxScale: 2.0,
        enableDoubleTapZoom: true,
        doubleTapZoomFactor: 0.8,
      ),
      focusNode: focusNode,
    );
  }

  void _showInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Genogram Instructions'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'About Genograms',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'A genogram is a visual representation of a family tree that includes additional information about relationships and medical history.',
              ),
              SizedBox(height: 16),
              Text(
                'Symbols',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Squares represent males'),
              Text('• Circles represent females'),
              Text('• Horizontal lines represent marriages'),
              Text('• Lines with slashes represent divorces'),
              SizedBox(height: 16),
              Text(
                'Navigation',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Pinch or scroll to zoom'),
              Text('• Drag to pan the view'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for divorce line (double slashes through line)
class DivorceLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw the main line
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );

    // Draw the two slashes
    canvas.drawLine(
      Offset(size.width / 3, 0),
      Offset(size.width / 3 + size.height, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 2 / 3, 0),
      Offset(size.width * 2 / 3 + size.height, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
