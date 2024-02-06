import 'package:flutter/material.dart';
import 'package:org_chart/org_chart.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Example2());
  }
}

class Example2 extends StatefulWidget {
  const Example2({super.key});

  @override
  State<Example2> createState() => _Example2State();
}

class _Example2State extends State<Example2> {
  final OrgChartController<Map> orgChartController = OrgChartController<Map>(
    boxSize: const Size(150, 50),
    items: [
      {
        "id": '1',
        "text": 'Main Block',
      },
    ],
    idProvider: (data) => data["id"],
    toProvider: (data) => data["to"],
  );

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.shade600,
                Colors.red.shade300,
              ],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                Center(
                  child: OrgChart<Map>(
                    // graph: orgChartController,
                    controller: orgChartController,
                    isDraggable: true,
                    linePaint: Paint()
                      ..color = Colors.black
                      ..strokeWidth = 5
                      ..style = PaintingStyle.stroke,
                    onTap: (item) {
                      orgChartController.addItem({
                        "id": orgChartController.uniqueNodeId,
                        "text": '',
                        "to": item["id"],
                      });
                      setState(() {});
                    },
                    onDoubleTap: (item) async {
                      String? text = await getBlockText(context, item);
                      if (text != null) setState(() => item["text"] = text);
                    },
                    builder: (details) {
                      return GestureDetector(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.black,
                              width: 2,
                            ),
                            color: details.isOverlapped
                                ? Colors.grey.shade600
                                : Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(child: Text(details.item["text"])),
                        ),
                      );
                    },
                    optionsBuilder: (item) {
                      return [
                        const PopupMenuItem(
                            value: 'promote', child: Text('Promote')),
                        const PopupMenuItem(
                            value: 'vacate', child: Text('Vacate Position')),
                        const PopupMenuItem(
                            value: 'Remove', child: Text('Remove')),
                      ];
                    },
                    onOptionSelect: (item, value) {
                      if (value == 'Remove') {
                        orgChartController.removeItem(item["id"]);
                        setState(() {});
                      }
                    },
                    onDrop: (dragged, target) {
                      dragged["to"] = target["id"];
                      orgChartController.calculatePosition();
                      setState(() {});
                    },
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: Text(
                      'Tap to add a node, double tap to change text\ndrag and drop to change hierarchy\nright click / tap and hold to remove \n Drag in the empty space to pan the chart, zoom in and out.\n'),
                )
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
                label: const Text('Reset & Change Orientation'),
                onPressed: () async {
                  orgChartController.orientation =
                      orgChartController.orientation ==
                              OrgChartOrientation.leftToRight
                          ? OrgChartOrientation.topToBottom
                          : OrgChartOrientation.leftToRight;
                  orgChartController.calculatePosition();
                  setState(() {});
                }),
          ),
        ),
      ],
    );
  }

  Future<String?> getBlockText(
      BuildContext context, Map<dynamic, dynamic> item) async {
    final String? text = await showDialog(
      context: context,
      builder: (context) {
        String text = item["text"];
        return AlertDialog(
          title: const Text('Enter Text'),
          content: TextFormField(
            initialValue: item["text"],
            onChanged: (value) {
              text = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(text);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    return text;
  }
}
