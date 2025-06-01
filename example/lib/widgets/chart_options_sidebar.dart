import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:org_chart/org_chart.dart';
import 'package:printing/printing.dart';
import 'dart:math' as math;

import '../models/chart_config.dart';
import '../utils/chart_utils.dart';

/// Widget that displays a sidebar with all chart configuration options
class ChartOptionsSidebar extends StatelessWidget {
  final ChartConfig config;
  final BaseGraphController controller;
  final CustomInteractiveViewerController interactiveViewerController;
  final Function(ChartConfig) onConfigChanged;
  final VoidCallback onAddNodePressed;
  final VoidCallback onResetLayoutPressed;

  const ChartOptionsSidebar({
    super.key,
    required this.config,
    required this.controller,
    required this.interactiveViewerController,
    required this.onConfigChanged,
    required this.onAddNodePressed,
    required this.onResetLayoutPressed,
  });
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: colorScheme.outlineVariant.withAlpha(77),
          width: 1,
        ),
      ),
      margin: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Chart Options',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Layout & Appearance
            _buildCategoryHeader(context, 'Layout & Appearance'),
            _buildLayoutSection(context),
            _buildAppearanceSection(context),

            // Navigation & Controls
            _buildCategoryHeader(context, 'Navigation & Controls'),
            _buildNodeFocusSection(context),
            _buildControllerActionsSection(context),
            _buildScaleSection(context),
            _buildKeyboardControlsSection(context),

            // Interaction
            _buildCategoryHeader(context, 'Interaction'),
            _buildInteractionSection(context),
            _buildAnimationSection(context),
            _buildInteractiveViewerSection(context),

            // Export & Actions
            _buildCategoryHeader(context, 'Export & Actions'),
            _buildActionsSection(context),
          ],
        ),
      ),
    );
  }

  /// Layout options section (orientation, spacing)
  Widget _buildLayoutSection(BuildContext context) {
    return _buildStyledExpansionTile(
      context,
      icon: Icons.dashboard_customize_rounded,
      title: 'Layout',
      initiallyExpanded: true,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Orientation',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withOpacity(0.5),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: ButtonTheme(
                    alignedDropdown: true,
                    child: DropdownButton<GraphOrientation>(
                      isExpanded: true,
                      value: config.orientation,
                      borderRadius: BorderRadius.circular(8),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      items: GraphOrientation.values
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(
                                e.name,
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          controller.switchOrientation(orientation: value);
                          config.orientation = value;
                          onConfigChanged(config);
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        ListTile(
          title: const Text('Node Spacing'),
          subtitle: Slider(
            value: config.nodeSpacing,
            min: 10,
            max: 100,
            divisions: 9,
            label: '${config.nodeSpacing.round()}',
            onChanged: (value) {
              controller.spacing = value;
              controller.calculatePosition();
              config.nodeSpacing = value;
              onConfigChanged(config);
            },
          ),
        ),
        ListTile(
          title: const Text('Level Spacing'),
          subtitle: Slider(
            value: config.levelSpacing,
            min: 20,
            max: 200,
            divisions: 9,
            label: '${config.levelSpacing.round()}',
            onChanged: (value) {
              controller.runSpacing = value;
              controller.calculatePosition();
              config.levelSpacing = value;
              onConfigChanged(config);
            },
          ),
        ),
        ListTile(
          title: Row(
            children: [
              const Text('Leaf Column Count'),
              const SizedBox(width: 4),
              Tooltip(
                message:
                    'Number of columns to use when arranging leaf nodes (nodes without children)',
                child: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  'Columns: ${config.leafColumnCount}',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: config.leafColumnCount.toDouble(),
                      min: 1,
                      max: 8,
                      divisions: 7,
                      label: '${config.leafColumnCount}',
                      onChanged: (value) {
                        // Since leafColumns is final, we need to recreate the controller
                        config.leafColumnCount = value.toInt();
                        (controller as OrgChartController).leafColumns =
                            value.toInt();

                        controller.calculatePosition();
                        onConfigChanged(config);
                      },
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${config.leafColumnCount}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Appearance options section (corner radius, arrow style)
  Widget _buildAppearanceSection(BuildContext context) {
    return _buildStyledExpansionTile(
      context,
      icon: Icons.palette_outlined,
      title: 'Appearance',
      children: [
        ListTile(
          title: const Text('Corner Radius'),
          subtitle: Slider(
            value: config.cornerRadius,
            min: 0,
            max: 20,
            divisions: 10,
            label: '${config.cornerRadius.round()}',
            onChanged: (value) {
              config.cornerRadius = value;
              onConfigChanged(config);
            },
          ),
        ),
        ListTile(
          title: const Text('Arrow Style'),
          subtitle: DropdownButton<String>(
            isExpanded: true,
            value: config.arrowStyle is SolidGraphArrow ? 'straight' : 'dashed',
            items: [
              const DropdownMenuItem(
                  value: 'straight', child: Text('Straight')),
              const DropdownMenuItem(value: 'dashed', child: Text('Dashed')),
            ],
            onChanged: (value) {
              switch (value) {
                case 'straight':
                  config.arrowStyle = const SolidGraphArrow();
                  break;
                case 'dashed':
                  config.arrowStyle =
                      DashedGraphArrow(pattern: config.dashPattern);
                  break;
              }
              onConfigChanged(config);
            },
          ),
        ),

        // Enhanced Dashed Arrow Options - Show only when dashed style is selected
        if (config.arrowStyle is DashedGraphArrow) ...[
          const Padding(
            padding: EdgeInsets.only(left: 16.0, top: 8.0, bottom: 4.0),
            child: Text(
              'Dashed Arrow Options',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),

          // Pattern Type Selection
          ListTile(
            dense: true,
            title: const Text('Pattern Type'),
            subtitle: DropdownButton<String>(
              isExpanded: true,
              value: config.getDashPatternType(),
              items: const [
                DropdownMenuItem(
                    value: 'simple', child: Text('Simple (Dash-Gap)')),
                DropdownMenuItem(
                    value: 'complex',
                    child: Text('Complex (Multiple Patterns)')),
                DropdownMenuItem(value: 'dotted', child: Text('Dotted')),
              ],
              onChanged: (value) {
                switch (value) {
                  case 'simple':
                    config.dashPattern = [8.0, 4.0];
                    break;
                  case 'complex':
                    config.dashPattern = [15.0, 3.0, 3.0, 3.0];
                    break;
                  case 'dotted':
                    config.dashPattern = [1.0, 3.0];
                    break;
                }
                config.updateDashedArrowStyle();
                onConfigChanged(config);
              },
            ),
          ),

          // Pattern Length (number of elements)
          if (config.getDashPatternType() == 'complex')
            ListTile(
              dense: true,
              title: const Text('Pattern Elements'),
              subtitle: DropdownButton<int>(
                isExpanded: true,
                value: config.dashPattern.length,
                items: [
                  for (int i = 2; i <= 6; i += 2)
                    DropdownMenuItem(
                      value: i,
                      child: Text('${i ~/ 2} dash-gap pairs'),
                    ),
                ],
                onChanged: (value) {
                  if (value != config.dashPattern.length) {
                    if (value! > config.dashPattern.length) {
                      // Add more elements
                      config.dashPattern = List.from(config.dashPattern)
                        ..addAll(List.filled(
                            value - config.dashPattern.length, 4.0));
                    } else {
                      // Remove elements
                      config.dashPattern = config.dashPattern.sublist(0, value);
                    }
                    config.updateDashedArrowStyle();
                    onConfigChanged(config);
                  }
                },
              ),
            ),

          // Dynamic pattern sliders based on pattern length
          for (int i = 0; i < config.dashPattern.length; i++)
            ListTile(
              dense: true,
              title: Text(i % 2 == 0
                  ? 'Dash ${(i ~/ 2) + 1} Length'
                  : 'Gap ${(i ~/ 2) + 1} Length'),
              subtitle: Slider(
                value: config.dashPattern[i],
                min: i % 2 == 0 ? 1 : 0.5, // Dash min: 1, Gap min: 0.5
                max: i % 2 == 0 ? 20 : 15, // Dash max: 20, Gap max: 15
                divisions: i % 2 == 0 ? 19 : 14,
                label: config.dashPattern[i].toStringAsFixed(1),
                onChanged: (value) {
                  config.dashPattern[i] = value;
                  config.updateDashedArrowStyle();
                  onConfigChanged(config);
                },
              ),
            ),

          // Line Thickness
          ListTile(
            dense: true,
            title: const Text('Line Thickness'),
            subtitle: Slider(
              value: config.dashThickness,
              min: 0.5,
              max: 5,
              divisions: 9,
              label: config.dashThickness.toStringAsFixed(1),
              onChanged: (value) {
                config.dashThickness = value;
                config.updateDashedArrowStyle();
                onConfigChanged(config);
              },
            ),
          ),

          // Preset patterns
          ExpansionTile(
            title: const Text('Pattern Presets'),
            dense: true,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  _buildPatternPresetButton(context, 'Standard', [8.0, 4.0]),
                  _buildPatternPresetButton(context, 'Dots', [1.0, 3.0]),
                  _buildPatternPresetButton(
                      context, 'Long-Short', [12.0, 3.0, 4.0, 3.0]),
                  _buildPatternPresetButton(
                      context, 'Morse', [2.0, 2.0, 6.0, 2.0, 2.0, 6.0]),
                  _buildPatternPresetButton(
                      context, 'Railroad', [10.0, 5.0, 2.0, 5.0]),
                ],
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Interaction options section (dragging, zoom)
  Widget _buildInteractionSection(BuildContext context) {
    return _buildStyledExpansionTile(
      context,
      icon: Icons.touch_app_rounded,
      title: 'Interaction',
      children: [
        SwitchListTile(
          title: const Text('Enable Dragging'),
          subtitle: const Text('Allow nodes to be dragged'),
          value: config.isDraggable,
          onChanged: (value) {
            config.isDraggable = value;
            onConfigChanged(config);
          },
        ),
        SwitchListTile(
          title: const Text('Enable Zoom'),
          subtitle: const Text('Allow pinch to zoom'),
          value: config.enableZoom,
          onChanged: (value) {
            config.enableZoom = value;
            onConfigChanged(config);
          },
        )
      ],
    );
  }

  /// Animation options section (duration, curve)
  Widget _buildAnimationSection(BuildContext context) {
    return _buildStyledExpansionTile(
      context,
      icon: Icons.animation,
      title: 'Animation',
      children: [
        ListTile(
          title: const Text('Animation Duration'),
          subtitle: Slider(
            value: config.animationDuration.inMilliseconds.toDouble(),
            min: 100,
            max: 1000,
            divisions: 9,
            label: '${config.animationDuration.inMilliseconds}ms',
            onChanged: (value) {
              config.animationDuration = Duration(milliseconds: value.round());
              onConfigChanged(config);
            },
          ),
        ),
        ListTile(
          title: const Text('Animation Curve'),
          subtitle: DropdownButton<String>(
            isExpanded: true,
            value: ChartUtils.getCurveName(config.animationCurve),
            items: [
              const DropdownMenuItem(
                  value: 'easeInOut', child: Text('Ease In Out')),
              const DropdownMenuItem(value: 'easeIn', child: Text('Ease In')),
              const DropdownMenuItem(value: 'easeOut', child: Text('Ease Out')),
              const DropdownMenuItem(value: 'linear', child: Text('Linear')),
              const DropdownMenuItem(
                  value: 'elasticIn', child: Text('Elastic In')),
              const DropdownMenuItem(
                  value: 'elasticOut', child: Text('Elastic Out')),
              const DropdownMenuItem(
                  value: 'bounceIn', child: Text('Bounce In')),
              const DropdownMenuItem(
                  value: 'bounceOut', child: Text('Bounce Out')),
            ],
            onChanged: (value) {
              if (value != null) {
                config.animationCurve = ChartUtils.getCurveFromName(value);
                onConfigChanged(config);
              }
            },
          ),
        ),
      ],
    );
  }

  /// Interactive viewer options section (rotation, bounds, etc.)
  Widget _buildInteractiveViewerSection(BuildContext context) {
    return _buildStyledExpansionTile(
      context,
      icon: Icons.pan_tool_rounded,
      title: 'Interactive Controls',
      children: [
        SwitchListTile(
          title: const Text('Enable Rotation'),
          subtitle: const Text('Allow chart to be rotated'),
          value: config.enableRotation,
          onChanged: (value) {
            config.enableRotation = value;
            onConfigChanged(config);
          },
        ),
        SwitchListTile(
          title: const Text('Constrain Bounds'),
          subtitle: const Text('Keep chart within visible area'),
          value: config.constrainBounds,
          onChanged: (value) {
            config.constrainBounds = value;
            onConfigChanged(config);
          },
        ),
        SwitchListTile(
          title: const Text('Double-tap Zoom'),
          subtitle: const Text('Experimental!\nZoom in on double-tap'),
          value: config.enableDoubleTapZoom,
          onChanged: (value) {
            config.enableDoubleTapZoom = value;
            onConfigChanged(config);
          },
        ),
        ListTile(
          title: const Text('Double-tap Zoom Factor'),
          subtitle: Slider(
            value: config.doubleTapZoomFactor,
            min: 1.2,
            max: 4.0,
            divisions: 7,
            label: config.doubleTapZoomFactor.toStringAsFixed(1),
            onChanged: (value) {
              config.doubleTapZoomFactor = value;
              onConfigChanged(config);
            },
          ),
        ),
        SwitchListTile(
          title: const Text('Keyboard Controls'),
          subtitle: const Text('Navigate with arrow keys'),
          value: config.enableKeyboardControls,
          onChanged: (value) {
            config.enableKeyboardControls = value;
            onConfigChanged(config);
          },
        ),
        SwitchListTile(
          title: const Text('Ctrl+Scroll to Zoom'),
          subtitle: const Text('Use scroll wheel for zooming'),
          value: config.enableCtrlScrollToScale,
          onChanged: (value) {
            config.enableCtrlScrollToScale = value;
            onConfigChanged(config);
          },
        ),
        SwitchListTile(
          title: const Text('Enable Fling'),
          subtitle: const Text('Momentum after panning'),
          value: config.enableFling,
          onChanged: (value) {
            config.enableFling = value;
            onConfigChanged(config);
          },
        ),
      ],
    );
  }

  /// Scale options section (min/max scale)
  Widget _buildScaleSection(BuildContext context) {
    return _buildStyledExpansionTile(
      context,
      icon: Icons.zoom_in_map,
      title: 'Scale Settings',
      children: [
        ListTile(
          title: const Text('Minimum Scale'),
          subtitle: Slider(
            value: config.minScale,
            min: 0.1,
            max: 1.0,
            divisions: 9,
            label: config.minScale.toStringAsFixed(1),
            onChanged: (value) {
              config.minScale = value;
              onConfigChanged(config);
            },
          ),
        ),
        ListTile(
          title: const Text('Maximum Scale'),
          subtitle: Slider(
            value: config.maxScale,
            min: 2.0,
            max: 10.0,
            divisions: 8,
            label: config.maxScale.toStringAsFixed(1),
            onChanged: (value) {
              config.maxScale = value;
              onConfigChanged(config);
            },
          ),
        ),
      ],
    );
  }

  /// Actions section (add node, export chart, reset layout)
  Widget _buildActionsSection(BuildContext context) {
    return _buildStyledExpansionTile(
      context,
      icon: Icons.play_circle_outline,
      title: 'Actions',
      children: [
        ListTile(
          leading: const Icon(Icons.add),
          title: const Text('Add New Node'),
          onTap: onAddNodePressed,
        ),
        ListTile(
          leading: const Icon(Icons.save),
          title: const Text('Export Chart As PDF'),
          onTap: () async {
            if (kIsWeb) {
              await _showWebExportWarning(context);
            }

            final pdf = await controller.exportAsPdf();
            if (pdf != null) {
              await Printing.layoutPdf(onLayout: (format) async {
                return await compute((data) async {
                  return await data.save();
                }, pdf);
              });
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.save),
          title: const Text('Export Chart As Image'),
          onTap: () async {
            if (kIsWeb) {
              await _showWebExportWarning(context);
            }

            final image = await controller.exportAsImage();
            if (image != null) {
              await showDialog(
                  context: context,
                  builder: (c) {
                    return AlertDialog(
                      content: Image.memory(image),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Close'),
                        ),
                      ],
                    );
                  });
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.restore),
          title: const Text('Reset Layout'),
          onTap: onResetLayoutPressed,
        ),
      ],
    );
  }

  /// Shows a warning dialog for web exports which may freeze the UI thread
  Future<void> _showWebExportWarning(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            const Text('Export Warning'),
          ],
        ),
        content: const Text(
            'On web platforms, the UI thread may temporarily be freezed when exporting.\n\n'
            'This is expected behavior and the application will be resumed once the export is complete.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  /// Node focus section (center on specific nodes)
  Widget _buildNodeFocusSection(BuildContext context) {
    return _buildStyledExpansionTile(
      context,
      icon: Icons.center_focus_strong,
      title: 'Focus on Node',
      children: [
        ListTile(
          title: const Text('Select Node to Center'),
          subtitle: DropdownButton<String>(
            isExpanded: true,
            value: config.zoomOnNodeId,
            items: controller.items
                .map((node) => DropdownMenuItem(
                      value: node['id'] as String,
                      child: Text(node['name'] as String),
                    ))
                .toList(),
            onChanged: (value) {
              config.zoomOnNodeId = value;
              onConfigChanged(config);
            },
          ),
        ),
        ListTile(
          title: const Text('Zoom Level'),
          subtitle: Row(
            children: [
              Expanded(
                child: Slider(
                  value: config.zoomOnNodeScaleFactor,
                  min: 0.8,
                  max: 3.0,
                  divisions: 9,
                  label:
                      '${config.zoomOnNodeScaleFactor.toStringAsPrecision(2)}x',
                  onChanged: (value) {
                    config.zoomOnNodeScaleFactor = value;
                    onConfigChanged(config);
                  },
                ),
              ),
              OutlinedButton(
                child: const Text('Go'),
                onPressed: () {
                  // Use the selected node and zoom level
                  if (config.zoomOnNodeId != null) {
                    controller.centerNode(config.zoomOnNodeId!,
                        scale: config.zoomOnNodeScaleFactor);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Controller actions section (direct manipulation through controller)
  Widget _buildControllerActionsSection(BuildContext context) {
    return _buildStyledExpansionTile(
      context,
      icon: Icons.gamepad_outlined,
      title: 'Controller Actions',
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.zoom_in),
              tooltip: 'Zoom In',
              onPressed: () {
                interactiveViewerController.zoom(factor: 0.2);
              },
            ),
            IconButton(
              icon: const Icon(Icons.zoom_out),
              tooltip: 'Zoom Out',
              onPressed: () {
                interactiveViewerController.zoom(factor: -0.2);
              },
            ),
            IconButton(
              icon: const Icon(Icons.rotate_90_degrees_ccw),
              tooltip: 'Rotate Left',
              onPressed: () {
                interactiveViewerController.rotate(math.pi / 5);
              },
            ),
            IconButton(
              icon: const Icon(Icons.rotate_90_degrees_cw),
              tooltip: 'Rotate Right',
              onPressed: () {
                interactiveViewerController.rotate(-math.pi / 5);
              },
            ),
          ],
        ),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_upward),
              tooltip: 'Pan Up',
              onPressed: () {
                interactiveViewerController.pan(const Offset(0, -50));
              },
            ),
            IconButton(
              icon: const Icon(Icons.arrow_downward),
              tooltip: 'Pan Down',
              onPressed: () {
                interactiveViewerController.pan(const Offset(0, 50));
              },
            ),
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Pan Left',
              onPressed: () {
                interactiveViewerController.pan(const Offset(-50, 0));
              },
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              tooltip: 'Pan Right',
              onPressed: () {
                interactiveViewerController.pan(const Offset(50, 0));
              },
            ),
          ],
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.center_focus_strong),
          title: const Text('Center Chart'),
          onTap: () {
            interactiveViewerController.center();
          },
        ),
        ListTile(
          leading: const Icon(Icons.restart_alt),
          title: const Text('Reset Transforms'),
          onTap: () {
            interactiveViewerController.reset();
          },
        ),
      ],
    );
  }

  /// Keyboard controls section
  Widget _buildKeyboardControlsSection(BuildContext context) {
    return _buildStyledExpansionTile(
      context,
      icon: Icons.keyboard_alt_outlined,
      title: 'Keyboard Controls',
      children: [
        SwitchListTile(
          title: const Text('Enable Keyboard Controls'),
          subtitle: const Text('Allow navigation with arrow keys'),
          value: config.enableKeyboardControls,
          onChanged: (value) {
            config.enableKeyboardControls = value;
            onConfigChanged(config);
          },
        ),
        SwitchListTile(
          title: const Text('Invert Arrow Key Direction'),
          subtitle: const Text('Reverse the direction of arrow key navigation'),
          value: config.invertArrowKeyDirection,
          onChanged: (value) {
            config.invertArrowKeyDirection = value;
            onConfigChanged(config);
          },
        ),
        ListTile(
          title: const Text('Pan Distance'),
          subtitle: Slider(
            value: config.keyboardPanDistance,
            min: 5,
            max: 50,
            divisions: 9,
            label: '${config.keyboardPanDistance.toStringAsFixed(0)} px',
            onChanged: (value) {
              config.keyboardPanDistance = value;
              onConfigChanged(config);
            },
          ),
        ),
        ListTile(
          title: const Text('Zoom Factor'),
          subtitle: Slider(
            value: config.keyboardZoomFactor,
            min: 1.01,
            max: 1.5,
            divisions: 9,
            label: 'x${config.keyboardZoomFactor.toStringAsFixed(2)}',
            onChanged: (value) {
              config.keyboardZoomFactor = value;
              onConfigChanged(config);
            },
          ),
        ),
        SwitchListTile(
          title: const Text('Enable Key Repeat'),
          subtitle: const Text('Allow holding keys for continuous action'),
          value: config.enableKeyRepeat,
          onChanged: (value) {
            config.enableKeyRepeat = value;
            onConfigChanged(config);
          },
        ),
        ListTile(
          title: const Text('Key Repeat Initial Delay'),
          subtitle: Slider(
            value: config.keyRepeatInitialDelay.inMilliseconds.toDouble(),
            min: 100,
            max: 1000,
            divisions: 9,
            label: '${config.keyRepeatInitialDelay.inMilliseconds} ms',
            onChanged: (value) {
              config.keyRepeatInitialDelay =
                  Duration(milliseconds: value.round());
              onConfigChanged(config);
            },
          ),
        ),
        ListTile(
          title: const Text('Key Repeat Interval'),
          subtitle: Slider(
            value: config.keyRepeatInterval.inMilliseconds.toDouble(),
            min: 10,
            max: 200,
            divisions: 19,
            label: '${config.keyRepeatInterval.inMilliseconds} ms',
            onChanged: (value) {
              config.keyRepeatInterval = Duration(milliseconds: value.round());
              onConfigChanged(config);
            },
          ),
        ),

        const Divider(height: 24),

        // Keyboard animation section
        const Padding(
          padding: EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
          child: Text(
            'Keyboard Animation Settings',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),

        SwitchListTile(
          title: const Text('Animate Keyboard Transitions'),
          subtitle: const Text('Smooth animation when using keyboard'),
          value: config.animateKeyboardTransitions,
          onChanged: (value) {
            config.animateKeyboardTransitions = value;
            onConfigChanged(config);
          },
        ),
        ListTile(
          title: const Text('Animation Duration'),
          enabled: config.animateKeyboardTransitions,
          subtitle: Slider(
            value: config.keyboardAnimationDuration.inMilliseconds.toDouble(),
            min: 100,
            max: 800,
            divisions: 7,
            label: '${config.keyboardAnimationDuration.inMilliseconds} ms',
            onChanged: config.animateKeyboardTransitions
                ? (value) {
                    config.keyboardAnimationDuration =
                        Duration(milliseconds: value.round());
                    onConfigChanged(config);
                  }
                : null,
          ),
        ),
        ListTile(
          title: const Text('Animation Curve'),
          enabled: config.animateKeyboardTransitions,
          subtitle: DropdownButton<String>(
            isExpanded: true,
            value: ChartUtils.getCurveName(config.keyboardAnimationCurve),
            items: [
              const DropdownMenuItem(
                  value: 'easeInOut', child: Text('Ease In Out')),
              const DropdownMenuItem(value: 'easeIn', child: Text('Ease In')),
              const DropdownMenuItem(value: 'easeOut', child: Text('Ease Out')),
              const DropdownMenuItem(value: 'linear', child: Text('Linear')),
              const DropdownMenuItem(
                  value: 'elasticIn', child: Text('Elastic In')),
              const DropdownMenuItem(
                  value: 'elasticOut', child: Text('Elastic Out')),
              const DropdownMenuItem(
                  value: 'bounceIn', child: Text('Bounce In')),
              const DropdownMenuItem(
                  value: 'bounceOut', child: Text('Bounce Out')),
            ],
            onChanged: config.animateKeyboardTransitions
                ? (value) {
                    if (value != null) {
                      config.keyboardAnimationCurve =
                          ChartUtils.getCurveFromName(value);
                      onConfigChanged(config);
                    }
                  }
                : null,
          ),
        ),
      ],
    );
  }

  /// Helper method to build a preset pattern button
  Widget _buildPatternPresetButton(
      BuildContext context, String label, List<double> pattern) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        textStyle: const TextStyle(fontSize: 11),
      ),
      onPressed: () {
        config.dashPattern = List.from(pattern);
        config.updateDashedArrowStyle();
        onConfigChanged(config);
      },
      child: Text(label),
    );
  }

  /// Helper method to create consistently styled expansion tiles
  Widget _buildStyledExpansionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    bool initiallyExpanded = false,
    required List<Widget> children,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
          ),
        ),
        initiallyExpanded: initiallyExpanded,
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  /// Helper method to build category headers to organize sections
  Widget _buildCategoryHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
