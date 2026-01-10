import 'layout_graph.dart';
import 'layout_request.dart';
import 'layout_result.dart';
import 'org_chart_layout_graph.dart';
import 'genogram_layout_graph.dart';

/// Base interface for standalone (widget-agnostic) layout engines.
abstract class GraphLayoutEngine<G extends LayoutGraph> {
  LayoutResult layout(LayoutRequest<G> request);
}

/// Layout engine interface for OrgChart.
abstract class OrgChartLayoutEngine
    extends GraphLayoutEngine<OrgChartLayoutGraph> {}

/// Layout engine interface for Genogram.
abstract class GenogramLayoutEngine
    extends GraphLayoutEngine<GenogramLayoutGraph> {}
