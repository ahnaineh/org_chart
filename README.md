# Important
This is my first package
If you have any ideas regarding this please dont hesitate to contact me.
Openning an issue or a pull request is highly appreciated.

# TODO
- [✅] Achieve a relatively stable, easily customizable API
- [✅] Add orientation support
- [✅] Add arrow paint customization
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

- If 'isTargetSubnode' in the onDrop function is true, then setting the target a parent to the dragged node will result in crashing the app! The checking is now done automatically for you behind the scenes.


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
    toSetter: (data, newID) => data["to"] = newID,
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
                const PopupMenuItem(value: 'Remove', child: Text('Remove')),
              ];
            },
            onOptionSelect: (item, value) {
              if (value == 'Remove') {
                orgChartController.removeItem(item["id"], ActionOnNodeRemoval.unlink);
              }
            },
            onDrop: (dragged, target, isTargetSubnode) {
              if (isTargetSubnode) {
                showDialog(
                    context: context,
                    builder: (_) {
                      return AlertDialog(
                          title: const Text('Error'),
                          content: const Text('You cannot drop a node on a subnode'),
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
```

If you want to redraw the nodes in the original positions
Use
```dart
orgChartController.calculatePosition();
```


If you want to change the orientation of the org chart
Use
```dart
orgChartController.orientation = OrgChartOrientation.leftToRight; // or OrgChartOrientation.topToBottom
```




