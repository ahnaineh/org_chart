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
      {"title": 'S', "id": '1', "to": null},
      {
        "title": 'A',
        "id": '2',
        "to": '1',
      },
      {
        "title": 'V',
        "id": '3',
        "to": '1',
      },
      {
        "title": 'K',
        "id": '4',
        "to": '1',
      },
      {
        "title": 'K',
        "id": '5',
        "to": '2',
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
            builder: (node, beingDragged, isOverlapped) {
              return Card(
                color: beingDragged
                    ? Colors.blue
                    : isOverlapped
                        ? Colors.green
                        : Colors.red,
                elevation: 10,
                child: Center(
                  child: Text(node.data["title"]),
                ),
              );
            },
            optionsBuilder: (node) {
              return [
                const PopupMenuItem(value: 'Remove', child: Text('Remove')),
                const PopupMenuItem(child: Text('X1')),
                const PopupMenuItem(child: Text('X2')),
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
        floatingActionButton: FloatingActionButton(onPressed: () {
          graph.calculatePosition();
          setState(() {});
        }),
      ),
    );
  }
}
