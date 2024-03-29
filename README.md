# Important
This is my first package
If you have any ideas regarding this please dont hesitate to contact me.
Openning an issue or a pull request is highly appreciated.

# TODO
- [x] Achieve a relatively stable, easily customizable API
- [x] Add orientation support
- [x] Add arrow paint customization
- [ ] Add arrow styles
- [ ] Add arrow animations
- [ ] Write a detailed documentation


Do you want to add to this list? Open an issue or a pull request!


# Org Chart
A flutter orgranizational chart with drag and drop, zoom and pan, search, collapse/expand, and exteremly easy to customize the node shape!
Built entirely in flutter, so it works on all platforms supported by it!

<!-- [![Watch the example](https://img.youtube.com/vi/8pxS-MwHh9w/sddefault.jpg)](https://youtu.be/8pxS-MwHh9w) -->
[Try it out](https://ahnaineh.github.io/)!
![The example app](https://github.com/ahnaineh/org_chart/blob/c9d1ed3f80b6a8ceb13f12e3255d3511ec68d865/Sequence%2001_5.gif?raw=True)
<!-- <video controls src="example.mp4" title="Title"></video> -->


# Caution
- in this version if more than one node returns null from the toProvider, the 2nd node and its tree will be stacked above the first tree...
- Also after any usage of a orgChartController method that changes the orgChartController structure, you need to run setState() to redraw the orgChartController
- You are required to check that there are no loops in the orgChartController, otherwise the app will crash


## Usage
To use this package add `org_chart` as a [dependency in your pubspec.yaml file](https://flutter.dev/docs/development/packages-and-plugins/using-packages).

Don't forget to import the package
```dart
import 'package:org_chart/org_chart.dart';
```

# Controller implementation
```dart
  final OrgChartController<Map> orgChartController = OrgChartController<Map>(
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

```
idProvider is a function to return the unique id of the node

toProvider is a function to return the id of the parent node if any, 

## Widget implementation
```dart
import 'package:org_chart/org_chart.dart';

OrgChart(
    controller: orgChartController,
    curve: Curves.elasticOut, // customize the curve of the animation
    duration: 500, // customize the duration of the animation
    isDraggable: true, // enable or disable dragging
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
                        child:  Text(details.nodesHidden ?'Press to Unhide' : 'Press to Hide'),
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
```

If you want to redraw the nodes in the original positions
Use
```dart
orgChartController.calculatePosition();
setState(() {});
```


If you want to change the orientation of the org chart
Use
```dart
orgChartController.orientation = OrgChartOrientation.leftToRight; // or OrgChartOrientation.topToBottom
orgChartController.calculatePosition();
setState(() {});
```




