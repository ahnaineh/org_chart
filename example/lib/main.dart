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
  final Graph<Map> graph = Graph<Map>(
    boxSize: const Size(200, 100),
    items: [
      {"title": 'CEO', "id": '1', "to": null},
      {
        "title": 'HR Manager: John',
        "id": '2',
        "to": '1',
      },
      {
        "title": 'HR Officer: Jane',
        "id": '3',
        "to": '2',
      },
      {
        "title": 'Project Manager: Zuher',
        "id": '4',
        "to": '1',
      },
    ],
    idProvider: (data) => data["id"],
    toProvider: (data) => data["to"],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: OrgChart<Map>(
            graph: graph,
            // curve: Curves.easeOut,
            // duration: 500,
            isDraggable: true,
            builder: (details) {
              return Card(
                color: details.beingDragged
                    ? Colors.blue
                    : details.isOverlapped
                        ? Colors.green
                        : null,
                elevation: 10,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(details.item["title"]),
                      ElevatedButton(
                        onPressed: () {
                          details.hideNodes(!details.nodesHidden);
                        },
                        child: Text(details.nodesHidden
                            ? 'Press to Unhide'
                            : 'Press to Hide'),
                      )
                    ],
                  ),
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
            onPressed: () {
              graph.calculatePosition();
              setState(() {});
            }),
      ),
    );
  }
}
