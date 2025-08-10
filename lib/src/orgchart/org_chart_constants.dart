import 'package:flutter/material.dart';

/// Constants specific to OrgChart widget
class OrgChartConstants {
  // Prevent instantiation
  OrgChartConstants._();

  /// Default box size for organizational chart nodes
  static const Size defaultBoxSize = Size(200, 100);

  /// Default horizontal spacing between nodes
  static const double defaultSpacing = 20.0;

  /// Default vertical spacing between levels
  static const double defaultRunSpacing = 50.0;

  /// Default number of columns for arranging leaf nodes
  static const int defaultLeafColumns = 4;

  /// Default corner radius for curved edges
  static const double defaultCornerRadius = 15.0;
}
