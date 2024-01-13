
A flutter orgranizational chart with drag and drop, zoom and pan, search, collapse/expand, and exteremly easy to customize the node shape!
Built entirely in flutter, so it works on all platforms supported by it!
<!-- ## Features

TODO: List what your package can do. Maybe include images, gifs, or videos.

## Getting started -->
<!-- 
TODO: List prerequisites and provide or point to information on how to
start using the package. -->

## Usage
To use this package add `org_chart` as a [dependency in your pubspec.yaml file](https://flutter.dev/docs/development/packages-and-plugins/using-packages).

# Graph implementation
```dart
import 'package:org_chart/org_chart.dart';

final Graph<Map> graph = Graph(
    boxSize: const Size(200, 100),
    nodes: [
      {
        "title": 'A',
        "id": '1',
        "to": null,
      },
      {
        "title": 'B',
        "id": '2',
        "to": '1',
      },
    ].map((e) => Node(data: e)).toList(),
    idProvider: (data) => data["id"],
    toProvider: (data) => data["to"],
  );
```
idProvider is a function to return the unique id of the node

toProvider is a function to return the id of the parent node if any, 

# Caution
(in this version if more than one node returns null from the toProvider, the 2nd node and its tree will be stacked above the first tree...)

## Widget implementation
```dart
import 'package:org_chart/org_chart.dart';

OrgChart(
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
```
Use
```dart
graph.calculatePosition();
setState(() {});
`
When you want to redraw the nodes in the original positions



## Important
This is my first package
If you have any ideas regarding this please dont hesitate to contact me.
Openning an issue or a pull request is highly appreciated.