import 'package:flutter/material.dart';
import 'package:org_chart/src/genogram/genogram_enums.dart';
import 'package:org_chart/src/genogram/marriage_style.dart';

/// Configuration for genogram edge painter styling
class GenogramEdgeConfig {
  /// The style to use for standard marriages
  final MarriageStyle defaultMarriageStyle;

  /// The style to use for divorced marriages
  final MarriageStyle divorcedMarriageStyle;

  /// The stroke width to use for child connections
  final double childStrokeWidth;

  // The stroke width to use for child with single parent connections
  final double childSingleParentStrokeWidth;
  final Color childSingleParentColor;

  /// Colors to use for different marriage connections
  final List<Color> marriageColors;

  /// Creates a new genogram edge configuration with default styling
  const GenogramEdgeConfig({
    this.defaultMarriageStyle = const MarriageStyle(
      lineStyle: MarriageLineStyle(color: Colors.black, strokeWidth: 1.0),
    ),
    this.divorcedMarriageStyle = const MarriageStyle(
      lineStyle: MarriageLineStyle(color: Colors.black, strokeWidth: 1.0),
      decorator: DivorceDecorator(),
    ),
    this.childSingleParentStrokeWidth = 1.0,
    this.childSingleParentColor = Colors.black,
    this.childStrokeWidth = 1.0,
    this.marriageColors = const [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ],
  });

  /// Gets the appropriate marriage style based on the provided status
  MarriageStyle getMarriageStyle(MarriageStatus status) {
    switch (status) {
      case MarriageStatus.divorced:
        return divorcedMarriageStyle;
      case MarriageStatus.married:
        // default:
        return defaultMarriageStyle;
    }
  }

  /// Creates a copy of this configuration with the given properties replaced
  GenogramEdgeConfig copyWith({
    MarriageStyle? defaultMarriageStyle,
    MarriageStyle? divorcedMarriageStyle,
    double? childStrokeWidth,
    List<Color>? marriageColors,
    double? childSingleParentStrokeWidth,
    Color? childSingleParentColor,
  }) {
    return GenogramEdgeConfig(
      defaultMarriageStyle: defaultMarriageStyle ?? this.defaultMarriageStyle,
      divorcedMarriageStyle:
          divorcedMarriageStyle ?? this.divorcedMarriageStyle,
      childStrokeWidth: childStrokeWidth ?? this.childStrokeWidth,
      marriageColors: marriageColors ?? this.marriageColors,
      childSingleParentStrokeWidth:
          childSingleParentStrokeWidth ?? this.childSingleParentStrokeWidth,
      childSingleParentColor:
          childSingleParentColor ?? this.childSingleParentColor,
    );
  }
}
