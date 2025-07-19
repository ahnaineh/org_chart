import 'package:flutter/material.dart';

/// Constants specific to Genogram widget
class GenogramConstants {
  // Prevent instantiation
  GenogramConstants._();

  /// Default box size for genogram nodes
  static const Size defaultBoxSize = Size(150, 150);
  
  /// Default spacing for genogram charts
  static const double defaultSpacing = 30.0;
  
  /// Default vertical spacing between generations
  static const double defaultRunSpacing = 50.0;
}