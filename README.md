# Org Chart

A Flutter organizational chart package with drag and drop, zoom and pan, collapse/expand, and extremely easy node customization. Built entirely in Flutter, so it works on all platforms supported by Flutter!

[![Version](https://img.shields.io/badge/version-5.0.0--alpha.1-blue.svg)](https://pub.dev/packages/org_chart)
[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev)

[Try it out online!](https://ahnaineh.github.io/)

![The example app](https://github.com/ahnaineh/org_chart/blob/c9d1ed3f80b6a8ceb13f12e3255d3511ec68d865/Sequence%2001_5.gif?raw=True)

## Features

- 📊 Versatile organizational chart with multiple layout options
- 🔍 Zoomable and pannable interface
- 🔄 Dynamic drag and drop functionality
- 📱 Responsive design that works across all Flutter platforms
- 🎨 Highly customizable node appearance and behavior
- ↔️ Multiple orientation support (top-to-bottom, left-to-right)
- 🎯 Custom arrow styles and appearance
- 🧩 Collapsible/expandable nodes
- 👪 Genogram support with full relationship visualization
- ✨ Customizable edge styling for genogram relationships
- 💍 Different marriage line styles (married, divorced)

## Installation

Add `org_chart` as a dependency in your `pubspec.yaml` file:

```yaml
dependencies:
  org_chart: ^5.0.0-alpha.1
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

## Genogram Features

The package includes full support for family trees (genograms) with customizable relationship edges.

### Basic Genogram Usage

```dart
// Create a controller
final controller = GenogramController<Person>(
  items: people,
  idProvider: (person) => person.id,
  fatherProvider: (person) => person.fatherId,
  motherProvider: (person) => person.motherId,
  genderProvider: (person) => person.gender,
  spousesProvider: (person) => person.spouses,
);

// Create the genogram
Genogram<Person>(
  controller: controller,
  builder: (details) => YourCustomNodeWidget(person: details.item),
)
```

### Customizing Genogram Edges

The package offers extensive edge styling for genograms, including:

- Different marriage relationship styles (married, divorced, separated)
- Adoption and foster child indicators
- Custom colors, line types, and decorators

```dart
// Create a custom edge configuration
final edgeConfig = GenogramEdgeConfig(
  // Marriage line styles
  defaultMarriageStyle: MarriageStyle(
    lineStyle: MarriageLineStyle(
      color: Colors.blue.shade700,
      strokeWidth: 1.5,
    ),
  ),
  divorcedMarriageStyle: MarriageStyle(
    lineStyle: MarriageLineStyle(color: Colors.red),
    decorator: DivorceDecorator(), // Adds divorce indicator
  ),
  // Parent-child connection styles
  parentChildStyle: ParentChildConnectionStyle(
    color: Colors.black87,
    strokeWidth: 1.2,
  ),
);

// Apply to genogram
Genogram<Person>(
  controller: controller,
  edgeConfig: edgeConfig,
  marriageStatusProvider: (person, spouse) => getMarriageStatus(person, spouse),
  builder: (details) => YourCustomNodeWidget(person: details.item),
)
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
- 🚧 update toSetter. Allow using consts. 



## Contributing

If you have ideas for improvements or found a bug:

1. Open an issue or submit a pull request on [GitHub](https://github.com/ahnaineh/org_chart)
2. Follow the contribution guidelines
