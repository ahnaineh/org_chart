# TODO
- ✅ Build a stable, easily customizable API
- ✅ Add orientation support
- ✅ Add arrow paint customization
- ✅ Add arrow styles
- 🚧 Add arrow animations
- 🚧 Write a detailed documentation


Do you want to add to this list? Open an issue or a pull request!

# Catuion
Removed `ontTap` and `onDoubleTap` from the `OrgChart` widget. Because of these, when a button on the node is pressed, running the callback is delayed, so to remove this delay both of these were removed. You can still add a `GestureDetector` in the builder method to achieve the same functionality.

# Org Chart
A flutter orgranizational chart with drag and drop, zoom and pan, search, collapse/expand, and exteremly easy to customize the node shape!
Built entirely in flutter, so it works on all platforms supported by it!

[Try it out](https://ahnaineh.github.io/)!
![The example app](https://github.com/ahnaineh/org_chart/blob/c9d1ed3f80b6a8ceb13f12e3255d3511ec68d865/Sequence%2001_5.gif?raw=True)


## Usage
To use this package add `org_chart` as a [dependency in your pubspec.yaml file](https://flutter.dev/docs/development/packages-and-plugins/using-packages).

Don't forget to import the package
```dart
import 'package:org_chart/org_chart.dart';
```

# Implementation
[Check the example](https://flutter.dev/docs/development/packages-and-plugins/using-packages)


If you want to redraw the nodes in the original positions
Use
```dart
orgChartController.calculatePosition();
// you can set center=false
```


If you want to change the orientation of the org chart
Use
```dart
orgChartController.switchOrientation(orientation=OrgChartOrientation.leftToRight);
// or OrgChartOrientation.topToBottom
// you can set center=false
```


# Important
This is my first package
If you have any ideas regarding this please dont hesitate to contact me.
Openning an issue or a pull request is highly appreciated.