library org_chart;

// Re-export from the specific OrgChart modules for backward compatibility
export 'src/graphs/org_chart/org_chart.dart' show OrgChart;
export 'src/controllers/org_chart_controller.dart'
    show OrgChartController, ActionOnNodeRemoval, OrgChartOrientation;

export 'src/common/edge_painter.dart' show SolidGraphArrow, DashedGraphArrow;
export 'src/common/node_builder_details.dart' show NodeBuilderDetails;

// For those who want the complete set of graph types, use:
// import 'package:org_chart/family_graphs.dart';
