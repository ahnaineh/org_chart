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
    boxSize: const Size(150, 80),
    items: [
      {
        "id": '0',
        "text": 'Main Block',
      },
      {
        "id": '1',
        "text": 'Block 2',
        "to": '0',
      },
      {
        "id": '2',
        "text": 'Block 3',
        "to": '0',
      },
      {
        "id": '3',
        "text": 'Block 4',
        "to": '1',
      },
    ],
    idProvider: (data) => data["id"],
    toProvider: (data) => data["to"],
    toSetter: (data, newID) => data["to"] = newID,
  );

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade100,
                Colors.blue.shade200,
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
                    cornerRadius: 10,
                    controller: orgChartController,
                    isDraggable: true,
                    linePaint: Paint()
                      ..color = Colors.black
                      ..strokeWidth = 5
                      ..style = PaintingStyle.stroke,
                    onTap: (item) {
                      orgChartController.addItem({
                        "id": orgChartController.uniqueNodeId,
                        "text": 'New Block',
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
                        child: Card(
                          elevation: 5,
                          color: details.isBeingDragged
                              ? Colors.green.shade100
                              : details.isOverlapped
                                  ? Colors.red.shade200
                                  : Colors.teal.shade50,
                          child: Center(
                              child: Text(
                            details.item["text"],
                            style: TextStyle(
                                color: Colors.purple.shade900, fontSize: 20),
                          )),
                        ),
                      );
                    },
                    optionsBuilder: (item) {
                      return [
                        const PopupMenuItem(
                            value: 'Remove', child: Text('Remove')),
                      ];
                    },
                    onOptionSelect: (item, value) {
                      if (value == 'Remove') {
                        orgChartController.removeItem(
                            item["id"], ActionOnNodeRemoval.unlink);
                      }
                    },
                    onDrop: (dragged, target, isTargetSubnode) {
                      if (isTargetSubnode) {
                        showDialog(
                            context: context,
                            builder: (_) {
                              return AlertDialog(
                                  title: const Text('Error'),
                                  content: const Text(
                                      'You cannot drop a node on a subnode'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('OK'),
                                    ),
                                  ]);
                            });
                        orgChartController.calculatePosition();

                        return;
                      }
                      dragged["to"] = target["id"];
                      orgChartController.calculatePosition();
                    },
                  ),
                ),
                const Positioned(
                  bottom: 20,
                  left: 20,
                  child: Text(
                      'Tap to add a node, double tap to change text\ndrag and drop to change hierarchy\nright click / tap and hold to remove \n Drag in the empty space to pan the chart, zoom in and out.\n'),
                )
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
                label: const Text('Reset & Change Orientation'),
                onPressed: () {
                  orgChartController.switchOrientation();
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
