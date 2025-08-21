## [5.0.1]
1. fix: missing setState in genogram calculatePosition method

## [5.0.0]
1. Stable


## [5.0.0-alpha.5]

### Performance Improvements
1. **Optimized node level calculations** - Added caching mechanism for `getLevel()` calls
   - 400x performance improvement (15ms vs 5000ms for 100k calls)
   - Cache automatically invalidated on node modifications

2. **Implemented parent-child index mapping** - O(1) lookups for `getSubNodes()`
   - 60x performance improvement (22ms vs 1000ms for 10k calls)  
   - Index automatically rebuilt on node modifications

3. **Added spatial indexing with QuadTree** - Optimized overlap detection
   - 80x performance improvement (24ms vs 2000ms for 1k calls in 2500 nodes)
   - Reduced complexity from O(n) to O(log n) for spatial queries

4. **Fixed edge painter efficiency** - Optimized `shouldRepaint` logic
   - Only repaints when actual properties change
   - Smoother animations and reduced CPU usage

### Added
- QuadTree implementation for spatial indexing (`lib/src/common/quadtree.dart`)
- Performance test suite to benchmark optimizations

### Internal Changes
- Modified `NodeQueryMixin` to include caching and indexing capabilities
- Updated `OrgChartController` to manage cache lifecycle
- Enhanced both `OrgChartEdgePainter` and `GenogramEdgePainter` with proper repaint conditions

### Additional Performance Improvements
5. **Implemented drag operation debouncing**
   - Reduced frequency of expensive overlap calculations during drag
   - Maintains smooth visual feedback while improving performance
   - Configurable debounce delay (default: 16ms for 60fps)


### Testing
- Added comprehensive test suite covering:
  - Core components (Node, QuadTree)
  - Controllers (OrgChartController with all operations)
  - Widgets (OrgChart rendering and interactions)
  - Performance optimizations verification
- Created test documentation and unified test runner
- Performance benchmarks included to verify optimization gains

### Code Quality
- Removed magic numbers throughout codebase
- Created separate constant classes for each component:
  - `OrgChartConstants` for org chart specific values
  - `GenogramConstants` for genogram specific values  
  - `BaseGraphConstants` for shared functionality
  - `QuadTreeConstants` for spatial indexing
- Improved maintainability and consistency


## [5.0.0-alpha.4]
....

## [5.0.0-alpha.3]

### Added
1. `addItems` method to the BaseController, allowing batch addition of nodes.
2. `clearItems` method to the BaseController, allowing clearing of all nodes in the chart.

### Changed
1. Reimplemented `addItem` such that both `addItem` and `addItems` replace the node if the node being added has the same ID as the one originally in the list.
2. Updated the `toSetter` method, now you return a new instance that replaces the old one, instead of modifying the old one in place, allowing you to use final instances with copyWith.
3. Updated the naming convention of `ActionOnNodeRemoval` to better reflect the purpose:
   - `unlink` → `unlinkDescendants`
   - `connectToParent` → `connectDescendantsToParent`
   - `remove` → `removeDescendants`


## [5.0.0-alpha.2]

### Added
1) Export functionality for charts - ability to export as PDF or image
2) Additional node styling options for better visualization (genogram)

### Improved
1) Performance optimizations for large charts with many nodes
2) More intuitive zoom and pan controls with configurable settings
3) Better handling of node visibility and centering
4) Refined user interface for chart manipulation

### Fixed
1) Resolved edge rendering issues in complex hierarchies
2) Fixed positioning calculation for nodes with specific relationship patterns
3) Improved node centering when some nodes are hidden
4) Addressed bugs related to node dragging and dropping


Bumped `custom_interactive_viewer` to version 0.0.6.


## [5.0.0-alpha.1]
Initial genogram implementation.


## [4.2.2]
### Fixed
1) Fixed an issue with node overlapping detection.


## [4.2.1]

### Fixed
1) Fix, the context menu was being rendered offsetted.
2) The node is checked for being hidden when centerNode method is used.

### Added
1) CustomInteractiveViewer now in focus on tap, allowing for the direct use of keyboard arrows, instead of needing to navigate to the graph using tab or arrow keys.
2) Added invertArrowDirection flag to the OrgChart widget.
3) Fix bugs in the example, and update with new changes.

Check [CustomInteractiveViewer](https://pub.dev/packages/custom_interactive_viewer/changelog) version 0.0.4 for more details.


## [4.2.0]

### Added
1) Implemented a [CustomInteractiveViewer](https://pub.dev/packages/custom_interactive_viewer) to replace the default one. Benefits include:
   - Fixed centering issues when zooming in/out and panning.
   - A new InteractiveViewerController allowing more control over the zoom and pan (and a new rotational 🔥) behavior in the graph.
   - fling behavior 😁
   - Fixed a bug in the `getSize` method of the `OrgChartController`. All nodes were checked, even hidden nodes, returning the wrong size. Which also caused issues in centering the graph.
   - Traverse the graph using keyboard arrows. zoom in and out using + & -

## [4.1.0]

### Added
- Recursive node removal functionality.
- Holding the Ctrl key changes trackpad scroll behavior to "scaling in".

### Fixed
- Resolved an issue where `removeItem` with `ActionOnNodeRemoval.connectToParent` incorrectly behaved like `ActionOnNodeRemoval.unlink`.

Thanks to [@fabionuno](https://github.com/fabionuno) for implementing all of these features and fixes!


## [4.0.2]

### Fixed
- Graph not being drawn due to a recursion issue.


## [4.0.1]

### Fixed
- Bug when centering the graph with some hidden nodes.


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


## [3.0.0+1]

### Changed
- Updated README.


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


## [2.2.0]

### Added
1. Support for top-to-bottom and left-to-right orientations.
2. Customizable arrow paint.
3. Resetting positions in the example also toggles orientation.

### Fixed
- Positioning bug for nodes with a single subnode chain.


## [2.1.0]

### Added
1. `onTap` and `onDoubleTap` to `OrgChart` widget.
2. `addItem` method in `Graph` for easier node addition.
3. A new example showcasing recent features.
4. `uniqueNodeId` method in `Graph` for auto-generating node IDs.

### Changed
- Minor arrow drawing tweaks.


## [2.0.1]

### Changed
- Code cleanup.


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


## [1.0.1]

### Changed
- No API changes.


## [1.0.0]

### Added
- First semi-stable implementation.
