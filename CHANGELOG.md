## [4.1.0] - 2025-04-11

### Added
- Recursive node removal functionality.
- Holding the Ctrl key changes trackpad scroll behavior to "scaling in".

### Fixed
- `removeItem` with `ActionOnNodeRemoval.connectToParent` now behaves correctly and no longer mimics `ActionOnNodeRemoval.unlink`.

Thanks to [@fabionuno](https://github.com/fabionuno) for implementing all of these features and fixes!

---

## [4.0.2]

### Fixed
- Graph not being drawn due to a recursion issue.

---

## [4.0.1]

### Fixed
- Bug when centering the graph with some hidden nodes.

---

## [4.0.0]

### Added
1. Dashed arrow styles:  
   - Introduced `arrowStyle` to the `OrgChart` widget with options `SolidGraphArrow` and `DashedGraphArrow`.

2. Graph centering:
   - Graph now centers on initialization and orientation change.
   - Can be disabled during orientation change using the new `center` parameter in `switchOrientation`.
   - The `orientation` setter is now deprecated.
   - `calculatePosition` also accepts the `center` parameter (defaults to `true`).
   - New `centerChart()` method added to controller.

3. Zoom control:
   - Exposed `minScale` and `maxScale` in the `OrgChart` widget.

4. Drag behavior:
   - Prevents dragging nodes into negative positions.
   - Fixed node index changing unnecessarily when starting to drag a node.

### Fixed
- Boundary issues where nodes could be placed out of view and become unclickable or undraggable.

### Removed
- Removed `onTap` and `onDoubleTap` from the `OrgChart` widget due to delayed callbacks. Use `GestureDetector` in the builder method instead.

### Updated
- Example project improvements.

---

## [3.1.0]

### Added
1. `switchOrientation` method on the controller to toggle orientation.
2. Automatic position recalculation when setting `controller.orientation`.

3. Spacing improvements:
   - Replaced `offset` with `spacing` and `runSpacing` based on current orientation.

4. Tree rendering:
   - Multiple roots now display side-by-side (or vertically) depending on orientation.

5. Visual polish:
   - Line radius added to leaf nodes.

6. Node removal improvements:
   - Added `idSetter` to controller for subnode reattachment.
   - New `action` parameter in `removeItem` with options:
     - `ActionOnNodeRemoval.unlink`
     - `ActionOnNodeRemoval.linkToParent`

---

## [3.0.0+1]

### Changed
- Updated README.

---

## [3.0.0]

### Changed
1. Major internal cleanup.
2. Fixed arrow-spacing calculation.
3. Added `cornerRadius` to customize arrow curves.
4. Added `level` to `NodeBuilderDetails` to indicate depth in tree.
5. Added `isTargetSubnode` to `onDrop` to detect drops on subnodes.
6. Updated and restyled example.
7. Removed deprecated `Graph` class and `graph` parameter from `OrgChart`.
8. Automatic UI updates after `calculatePosition` — no more need to call `setState`.
9. Only the first tree is shown if multiple roots exist.

---

## [2.2.0]

### Added
1. Support for top-to-bottom and left-to-right orientations.
2. Customizable arrow paint.
3. Resetting positions in the example also toggles orientation.

### Fixed
- Positioning bug for nodes with a single subnode chain.

---

## [2.1.0]

### Added
1. `onTap` and `onDoubleTap` to `OrgChart` widget.
2. `addItem` method in `Graph` for easier node addition.
3. A new example showcasing recent features.
4. `uniqueNodeId` method in `Graph` for auto-generating node IDs.

### Changed
- Minor arrow drawing tweaks.

---

## [2.0.1]

### Changed
- Code cleanup.

---

## [2.0.0]

### Changed
1. Removed the need to manually map data types to `Node` — done internally now.
2. Builder method now receives a `NodeBuilderDetails` object containing:
   - `data`
   - `hideNodes`
   - `nodesHidden`
   - `beingDragged`
   - `isOverlapped`
3. Added customizable animation curve and duration when resetting positions.
4. Added documentation and internal tweaks.

---

## [1.0.1]

### Changed
- No API changes.

---

## [1.0.0]

### Added
- First semi-stable implementation.
