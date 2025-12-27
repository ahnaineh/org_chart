# Plan: Edge Styling, Fading, and Labels (Widget-Based)

Goals:
- Provide a general, extensible edge API that supports edge fading and labels.
- Use widget-based labels for flexibility.
- Keep behavior backward compatible and consistent across chart types.

Non-Goals:
- Change existing defaults or visuals unless configured.
- Hard-code genogram-only behavior; design for future graph types (e.g., DAG).

Phase 0: Requirements + API Design
- [x] Define `EdgeInfo` data model (type, source/target nodes, orientation, points, metadata).
- [x] Define `EdgeStyle` model (color, strokeWidth, opacity, paint style).
- [x] Define `edgeStyleProvider(EdgeInfo) -> EdgeStyle` (single entry point, includes fading).
- [x] Define `edgeLabelBuilder(EdgeInfo) -> Widget?` (optional, returns null if no label).
- [x] Define `EdgeLabelConfig` (anchor, offset, rotation, clamp-to-bounds, overlap rules).
- [x] Decide where `EdgeInfo` lives (common package location) and document in API.

Phase 1: Internal Edge Representation
- [x] Refactor edge painters to build a canonical list of `EdgeInfo` objects.
- [x] Ensure edge list includes: org chart parent-child, genogram parent-child, genogram marriages.
- [x] Add stable `edgeId` for caching/repaint comparisons.
- [ ] Validate edge list correctness with unit tests (counts and endpoints).

Phase 2: Edge Styling Integration
- [x] Update `OrgChartEdgePainter` to use `edgeStyleProvider` for each edge.
- [x] Update `GenogramEdgePainter` to use `edgeStyleProvider` for each edge.
- [x] Implement default `EdgeStyle` mapping so visuals remain unchanged when provider is null.
- [x] Add fade-by-opacity example logic (via style provider, not a separate API).

Phase 3: Edge Label Rendering (Widget Overlay)
- [x] Add an edge-label overlay layer in `OrgChart` and `Genogram` stacks.
- [x] Compute label anchor points from `EdgeInfo` path midpoints.
- [x] Add `EdgeLabelConfig` controls for positioning, alignment, and rotation.
- [ ] Implement zoom-aware label scaling (optional toggle).
- [x] Add simple collision avoidance (greedy offset along edge normal).
- [x] Provide a safe fallback for when labels overlap or exceed bounds.
- [x] Support per-edge `labelPoint` overrides for precise placement.

Phase 4: Extensibility for Future Graph Types
- [x] Add `EdgeType` enum to cover genogram/org chart (DAG reserved).
- [x] Ensure `EdgeInfo` can carry arbitrary metadata (map) for DAG edge labels.
- [ ] Document how to implement a new graph type and edge creation pipeline.

Phase 5: Examples + Docs
- [x] Update example app: tap-to-fade unrelated nodes + edges via `edgeStyleProvider`.
- [x] Add widget labels in the example (marriage labels).
- [x] Document new APIs in genogram and org chart docs with code samples.
- [ ] Add migration guide (no breaking changes).
  - Notes: include new `spouseSpacing` and `marriageAnchorDistance` usage.

Phase 6: Testing + Performance
- [ ] Unit tests for edge list generation and style resolution.
- [ ] Golden tests for label placement (if available).
- [ ] Perf test for edge generation + label layout on medium graphs.
- [ ] Verify exports (PNG/PDF) include edge labels correctly.

Phase 7: Release
- [x] Update CHANGELOG with new API features and examples.
- [x] Bump version.
- [ ] Tag release.

Notes:
- Keep `edgeStyleProvider` the only customization entry point for fading and styling.
- Labels are widgets for flexibility; ensure rendering is deterministic and performant.
- Avoid breaking changes; if any are unavoidable, ship a migration guide.
