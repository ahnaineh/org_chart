# Org Chart Test Suite

This directory contains the comprehensive test suite for the Flutter Org Chart package.

## Test Structure

```
test/
├── core/                    # Core component tests
│   ├── node_test.dart      # Node class tests
│   └── quadtree_test.dart  # QuadTree spatial indexing tests
├── controllers/            # Controller tests  
│   └── org_chart_controller_test.dart
├── performance/            # Performance optimization tests
│   └── optimization_test.dart
├── widgets/               # Widget tests
│   └── org_chart_widget_test.dart  
├── performance_test.dart  # Performance benchmarks
└── all_tests.dart        # Test suite runner
```

## Running Tests

### Run all tests
```bash
flutter test
```

### Run specific test file
```bash
flutter test test/core/node_test.dart
```

### Run with coverage
```bash
flutter test --coverage
```

### Run all tests using the test suite
```bash
flutter test test/all_tests.dart
```

## Test Categories

### Core Tests
- **Node Tests**: Basic node creation, position, and distance calculations
- **QuadTree Tests**: Spatial indexing implementation

### Controller Tests
- Controller initialization
- Node management (add, remove, update)
- Hierarchy operations (get level, get subnodes, get parent)
- Different removal strategies

### Performance Tests
- Level calculation caching
- Parent-child index mapping
- QuadTree spatial queries
- Combined optimization tests

### Widget Tests
- Basic rendering
- Drag and drop functionality
- Node builder details
- Interactive viewer integration
- Empty chart handling

## Performance Benchmarks

The `performance_test.dart` file contains benchmarks for:
- getLevel() with caching (400x improvement)
- getSubNodes() with indexing (60x improvement)  
- getOverlapping() with QuadTree (80x improvement)

## Writing New Tests

When adding new features, please ensure:
1. Unit tests for core logic
2. Widget tests for UI components
3. Integration tests for feature combinations
4. Performance tests for any optimization

## Coverage Goals

Target: 90%+ test coverage for:
- Public APIs
- Core business logic
- Performance-critical paths
- Error handling

## CI/CD Integration

Tests are run automatically on:
- Pull requests
- Main branch commits
- Release tags

Failed tests will block merges and deployments.