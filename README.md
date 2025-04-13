# Org Chart

A Flutter organizational chart package with drag and drop, zoom and pan, search, collapse/expand, and extremely easy node customization. Built entirely in Flutter, so it works on all platforms supported by Flutter!

[![Version](https://img.shields.io/badge/version-4.2.0-blue.svg)](https://pub.dev/packages/org_chart)
[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev)

[Try it out online!](https://ahnaineh.github.io/)

![The example app](https://github.com/ahnaineh/org_chart/blob/c9d1ed3f80b6a8ceb13f12e3255d3511ec68d865/Sequence%2001_5.gif?raw=True)

## Features

- 📊 Versatile organizational chart with multiple layout options
- 🔍 Zoomable and pannable interface
- 🔄 Dynamic drag and drop functionality
- 🔍 Search capabilities
- 📱 Responsive design that works across all Flutter platforms
- 🎨 Highly customizable node appearance and behavior
- ↔️ Multiple orientation support (top-to-bottom, left-to-right)
- 🎯 Custom arrow styles and appearance
- 🧩 Collapsible/expandable nodes

## Installation

Add `org_chart` as a dependency in your `pubspec.yaml` file:

```yaml
dependencies:
  org_chart: ^4.2.0
```

Then run:

```bash
flutter pub get
```

## Basic Usage

Import the package:

```dart
import 'package:org_chart/org_chart.dart';
```

Create a basic organizational chart:

```dart
// Create a controller
final controller = OrgChartController();

// Build your chart
OrgChart(
  controller: controller,
  // Define your nodes
  nodes: [
    Node(
      id: '1',
      parent: null, // Root node
      builder: (context, details) => YourCustomNodeWidget(),
    ),
    Node(
      id: '2',
      parent: '1', // Child of node with id '1'
      builder: (context, details) => YourCustomNodeWidget(),
    ),
    // Add more nodes as needed
  ],
)
```

## Advanced Usage

### Controlling Node Positions

Recalculate node positions:

```dart
// Redraw nodes in their original positions
controller.calculatePosition();

// You can disable centering
controller.calculatePosition(center: false);
```

### Changing Orientation

Switch between different layout orientations:

```dart
// Switch to left-to-right orientation
controller.switchOrientation(orientation: OrgChartOrientation.leftToRight);

// Switch to top-to-bottom orientation
controller.switchOrientation(orientation: OrgChartOrientation.topToBottom);

// Disable centering when switching orientation
controller.switchOrientation(
  orientation: OrgChartOrientation.leftToRight,
  center: false,
);
```

## Documentation

For more detailed documentation and examples, please check:

- [API Documentation](https://pub.dev/documentation/org_chart/latest/)
- [Example Project](https://pub.dev/packages/org_chart/example)

## Roadmap

Completed:
- ✅ Build a stable, easily customizable API
- ✅ Add orientation support
- ✅ Add arrow paint customization
- ✅ Add arrow styles

In Progress:
- 🚧 Add arrow animations
- 🚧 Write detailed documentation



## Contributing

If you have ideas for improvements or found a bug:

1. Open an issue or submit a pull request on [GitHub](https://github.com/ahnaineh/org_chart)
2. Follow the contribution guidelines
