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
  final Graph<Map> graph = Graph<Map>(
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
    return Container(
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
        body: Center(
          child: OrgChart<Map>(
            graph: graph,
            isDraggable: true,
            onTap: (item) {
              graph.addItem({
                "id": graph.uniqueNodeId,
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
                const PopupMenuItem(value: 'promote', child: Text('Promote')),
                const PopupMenuItem(
                    value: 'vacate', child: Text('Vacate Position')),
                const PopupMenuItem(value: 'Remove', child: Text('Remove')),
              ];
            },
            onOptionSelect: (item, value) {
              if (value == 'Remove') {
                graph.removeItem(item["id"]);
                setState(() {});
              }
            },
            onDrop: (dragged, target) {
              dragged["to"] = target["id"];
              graph.calculatePosition();
              setState(() {});
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
            child: const Text('Reset Position'),
            onPressed: () async {
              graph.calculatePosition();
              setState(() {});
            }),
      ),
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
