library org_chart;

// Working on V4!

import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:org_chart/custom_animated_positioned.dart';

// Size SPACING = const Size(20, 50);

class OrgChart<E> extends StatefulWidget {
  final Graph<E> graph;
  final Widget Function(
    Node<E> node,
    bool beingDragged,
    bool isOverlapped,
  ) builder;
  final List<PopupMenuEntry<dynamic>> Function(Node<E> node)? optionsBuilder;
  final void Function(E item, dynamic value)? onOptionSelect;
  final void Function(E dragged, E target)? onDrop;
  final bool isDraggable;
  const OrgChart({
    super.key,
    required this.graph,
    required this.builder,
    this.optionsBuilder,
    this.onOptionSelect,
    this.onDrop,
    this.isDraggable = true,
  });

  @override
  State<OrgChart<E>> createState() => _OrgChartState();
}

class _OrgChartState<E> extends State<OrgChart<E>> {
  List<Node<E>> overlapping = [];
  String? draggedID;

  @override
  Widget build(BuildContext context) {
    Offset size = widget.graph.getSize();
    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(1000),
      minScale: 0.001,
      maxScale: 5.6,
      child: SizedBox(
        width: size.dx + 100,
        height: size.dy + 100,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            CustomPaint(
              size: MediaQuery.of(context).size,
              painter: EdgePainter<E>(graph: widget.graph),
            ),
            ...draw(context)
              //
              ..sort((a, b) => a.isBeingDragged ? 1 : -1)
            //
            ,
          ],
        ),
      ),
    );
  }

  List<CustomAnimatedPositioned> draw(context,
      {List<Node<E>>? nodesToDraw, bool hidden = false}) {
    nodesToDraw ??= widget.graph.roots;
    List<CustomAnimatedPositioned> widgets = [];

    for (int i = 0; i < nodesToDraw.length; i++) {
      Node<E> node = nodesToDraw[i];
      widgets.add(CustomAnimatedPositioned(
          key: Key("ID: ${widget.graph.idProvider(node.data)}"),
          isBeingDragged: draggedID == widget.graph.idProvider(node.data),
          curve: Curves.elasticOut,
          // elasticOut easeInOut
          // return -(pow(e, -t / a) * cos(t * w)) + 1;
          duration: Duration(milliseconds: draggedID != null ? 0 : 700),
          top: node.position.dy,
          left: node.position.dx,
          child: hidden
              ? const SizedBox.shrink()
              : AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: hidden ? 0 : 1,
                  child: GestureDetector(
                    onTapDown: (TapDownDetails details) {
                      final RenderBox referenceBox =
                          context.findRenderObject() as RenderBox;
                      panDownPosition =
                          referenceBox.globalToLocal(details.globalPosition);
                    },
                    onLongPress: () async => await _showMenu(context, node),
                    onSecondaryTapDown: (TapDownDetails details) {
                      final RenderBox referenceBox =
                          context.findRenderObject() as RenderBox;
                      panDownPosition =
                          referenceBox.globalToLocal(details.globalPosition);
                    },
                    onSecondaryTap: () async => await _showMenu(context, node),
                    onPanStart: widget.isDraggable
                        ? (details) {
                            widget.graph.changeNodeIndex(node, -1);

                            draggedID = widget.graph.idProvider(node.data);
                          }
                        : null,
                    onPanEnd: widget.isDraggable
                        ? (details) {
                            if (overlapping.isNotEmpty) {
                              widget.onDrop
                                  ?.call(node.data, overlapping.first.data);
                            }
                            draggedID = null;
                            overlapping = [];
                            setState(() {});
                          }
                        : null,
                    onPanUpdate: widget.isDraggable
                        ? (details) {
                            overlapping = _getOverlapping(node);
                            overlapping.sort((a, b) =>
                                _distance(a.position, node.position).compareTo(
                                    _distance(b.position, node.position)));
                            setState(() => node.position += details.delta);
                          }
                        : null,
                    child: SizedBox(
                      height: widget.graph.boxSize.height,
                      width: widget.graph.boxSize.width,
                      child: widget.builder(
                        node,
                        draggedID == widget.graph.idProvider(node.data),
                        overlapping.isNotEmpty && overlapping.first == node,
                        // widget.graph.calculatePosition, setState
                      ),
                    ),
                  ),
                )));
      widgets.addAll(draw(context,
          nodesToDraw: widget.graph._nodes
              .where((n) =>
                  widget.graph.toProvider(n.data) ==
                  widget.graph.idProvider(node.data))
              .toList(),
          hidden: node.hideNodes || hidden));
    }
    return widgets;
  }

  double _distance(Offset a, Offset b) {
    return math.sqrt(math.pow(a.dx - b.dx, 2) + math.pow(a.dy - b.dy, 2));
  }

  Offset? panDownPosition;

  _showMenu(context, node) async {
    List<PopupMenuEntry<dynamic>> options =
        widget.optionsBuilder?.call(node) ?? [];
    if (options.isEmpty) return;
    final RenderObject? overlay =
        Overlay.of(context).context.findRenderObject();

    final result = await showMenu(
      context: context,

      // Show the context menu at the tap location
      position: RelativeRect.fromRect(
          Rect.fromLTWH(panDownPosition!.dx, panDownPosition!.dy, 30, 30),
          Rect.fromLTWH(0, 0, overlay!.paintBounds.size.width,
              overlay.paintBounds.size.height)),

      // set a list of choices for the context menu
      items: options,
    );

    widget.onOptionSelect?.call(node, result);
  }

  List<Node<E>> _getOverlapping(Node<E> node) {
    List<Node<E>> overlapping = [];
    for (Node<E> n in widget.graph._nodes.cast<Node<E>>()) {
      Offset offset = node.position - n.position;
      if (offset.dx.abs() < 100 &&
          offset.dy.abs() < 100 &&
          widget.graph.idProvider(node.data) !=
              widget.graph.idProvider(n.data)) {
        overlapping.add(n);
        // }
        // TODO: reenable node hiding
        // if (!hideNodes) {
        //   for (Node<E> n in nodes) {
        //     overlapping.addAll(n.getOverlapping(node));
        //   }
      }
    }

    return overlapping;
  }
}

class Node<E> {
  // String id;
  // String? to;
  Offset position;
  // Color color;
  E data;
  bool hideNodes;

  Node({
    // required this.id,
    // this.to,
    required this.data,
    this.position = Offset.zero,
    // required this.color,
    this.hideNodes = false,
  });

  Offset distance(Node node) => node.position - position;
}

class Graph<E> {
  late List<Node<E>> _nodes;
  Size boxSize;
  Size spacing;

  String? Function(E data) idProvider;
  String? Function(E data) toProvider;
  Graph({
    // required this.nodes,
    required List<E> items,
    // required this.builder,
    // this.onDrop,
    // this.optionsBuilder,
    // this.onOptionSelect,
    this.boxSize = const Size(200, 100),
    this.spacing = const Size(20, 50),
    required this.idProvider,
    required this.toProvider,

    // this.sizeCalculator,
  }) : super() {
    _nodes = items.map((e) => Node(data: e)).toList();
    calculatePosition();
    // sizeCalculator ??= (node) => boxSize;
  }

  void removeItem(id) {
    _nodes.removeWhere((element) => idProvider(element.data) == id);
    calculatePosition();
  }

  _getLevel(Node<E> node) {
    int level = 1;
    Node<E>? next = node;
    while (next != null) {
      try {
        next = _nodes
            .firstWhere((n) => idProvider(n.data) == toProvider(next!.data));
        level++;
      } catch (e) {
        next = null;
      }
    }
    return level;
  }

  List<Node<E>> get roots {
    return _nodes
        .where((node) => _nodes
            .where(
                (element) => idProvider(element.data) == toProvider(node.data))
            .isEmpty)
        .toList();
  }

  void changeNodeIndex(Node<E> node, index) {
    _nodes.remove(node);
    _nodes.insert(index == -1 ? math.max(_nodes.length - 1, 0) : index, node);
  }

  double _getRelOffset(Node<E> node) {
    // bool hideNodes = false; // TODO: re enable hiding

    List<Node<E>> subNodes = getSubNodes(node);

    if (node.hideNodes || subNodes.isEmpty) {
      return boxSize.width + spacing.width * 2;
    }

    double relativeOffset = 0.0;

    if (allLeaf(subNodes)) {
      return (subNodes.length > 1
          ? boxSize.width * 2 + spacing.width * 3
          : boxSize.width + spacing.width * 2);
    } else {
      for (var i = 0; i < subNodes.length; i++) {
        relativeOffset += _getRelOffset(subNodes[i]);
      }
    }
    return relativeOffset;
  }

  //TODO: finish this

  // moveTo(Node<E> from, Node<E> to) => from.to = to.id;

  // add or hideNodes == true
  allLeaf(List<Node<E>> nodes) {
    return nodes
        .every((element) => getSubNodes(element).isEmpty || element.hideNodes);
  }

  List<Node<E>> getSubNodes(Node<E> node) {
    return _nodes
        .where((element) => toProvider(element.data) == idProvider(node.data))
        .toList();
  }

  _calculateNP(Node<E> node, {Offset offset = const Offset(0, 0)}) {
    List<Node<E>> subNodes = getSubNodes(node);

    if (allLeaf(subNodes)) {
      for (var i = 0; i < subNodes.length; i++) {
        subNodes[i].position = offset +
            Offset(
                i % 2 == 0
                    ? subNodes.length > i + 1 || subNodes.length == 1
                        ? 0
                        : boxSize.width / 2 + spacing.width / 2
                    : spacing.width + boxSize.width,
                (_getLevel(subNodes[i]) + i ~/ 2) *
                    (boxSize.height + spacing.height));
      }
      node.position = offset +
          Offset(
              (subNodes.length > 1 ? boxSize.width / 2 + spacing.width / 2 : 0),
              _getLevel(node) * (boxSize.height + spacing.height));
      return (subNodes.length > 1
          ? boxSize.width * 2 + spacing.width * 3
          : boxSize.width + spacing.width * 2);
    } else {
      double dxOff = 0;
      for (var i = 0; i < subNodes.length; i++) {
        dxOff += _calculateNP(subNodes[i],
            offset: offset + Offset(dxOff + spacing.width, 0));
      }
      double relOff = _getRelOffset(node);
      dxOff = 0;
      node.position = subNodes.length == 1
          ? Offset(subNodes.first.position.dx,
              _getLevel(node) * (boxSize.height + spacing.height))
          : offset +
              Offset(relOff / 2 - boxSize.width / 2,
                  _getLevel(node) * (boxSize.height + spacing.height));
      return relOff;
    }
  }

  void calculatePosition() {
    for (Node<E> node in _nodes.where((element) => _getLevel(element) == 1)) {
      _calculateNP(node);
    }
  }

  getSize({Offset offset = const Offset(0, 0)}) {
    for (Node node in _nodes) {
      offset = Offset(
        math.max(offset.dx, node.position.dx),
        math.max(offset.dy, node.position.dy),
      );
    }
    return offset;
  }
}

class EdgePainter<E> extends CustomPainter {
  // List<Node> nodes;
  // Size boxSize;
  Graph<E> graph;
  var linePath = Path();
  EdgePainter({required this.graph});
  allLeaf(List<Node> nodes) {
    return nodes
        .every((element) => getSubNodes(element).isEmpty || element.hideNodes);
  }

  List<Node> getSubNodes(Node node) {
    return graph._nodes
        .where((element) =>
            graph.toProvider(element.data) == graph.idProvider(node.data))
        .toList();
  }

  drawArrows(Node node) {
    List<Node> subNodes = getSubNodes(node);
    if (node.hideNodes == false) {
      if (allLeaf(subNodes)) {
        for (var n in subNodes) {
          linePath.moveTo(node.position.dx + graph.boxSize.width / 2,
              node.position.dy + graph.boxSize.height / 2);
          linePath.lineTo(node.position.dx + graph.boxSize.width / 2,
              n.position.dy + graph.boxSize.height / 2);
          linePath.lineTo(n.position.dx + graph.boxSize.width / 2,
              n.position.dy + graph.boxSize.height / 2);
        }
      } else {
        for (var n in subNodes) {
          final minx = math.min(node.position.dx, n.position.dx);
          final maxx = math.max(node.position.dx, n.position.dx);
          final miny = math.min(node.position.dy, n.position.dy);
          final maxy = math.max(node.position.dy, n.position.dy);

          // final dx = (maxx - minx) / 2 + 50;
          final dy = (maxy - miny) / 2 + 50;

          // bool b = maxx == node.position.dx;

          linePath.moveTo(node.position.dx + graph.boxSize.width / 2,
              node.position.dy + graph.boxSize.height);

          linePath.lineTo(
              node.position.dx + graph.boxSize.width / 2, miny + dy);

          if (maxx - minx > 15) {
            // linePath.arcToPoint(
            //     Offset(node.position.dx + graph.boxSize.width / 2 + (b ? -10 : 10),
            //         miny + dy),
            //     radius: const Radius.circular(10),
            //     clockwise: b);

            linePath.lineTo(n.position.dx + graph.boxSize.width / 2, miny + dy);
            // + (!b ? -10 : 10)

            // linePath.arcToPoint(
            //     Offset(n.position.dx + graph.boxSize.width / 2, miny + dy + 10),
            //     radius: const Radius.circular(10),
            //     clockwise: !b);
          }

          linePath.lineTo(n.position.dx + graph.boxSize.width / 2,
              n.position.dy + graph.boxSize.height / 2);

          drawArrows(n);
        }
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    var edgePaint = (Paint()
      ..color = Colors.black
      ..strokeWidth = 3)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    linePath.reset();
    for (var node in graph.roots) {
      drawArrows(node);
    }

    canvas.drawPath(linePath, edgePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

// /////////////////////////////////////////////////////////////////////////////////
//                Usage
// /////////////////////////////////////////////////////////////////////////////////
/**

import 'package:flutter/material.dart';
import 'package:org_chart/org_chart.dart';

void main() {
  runApp(MainApp());
}

class MainApp extends StatefulWidget {
  MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final Graph graph = Graph(
    boxSize: Size(200, 500),
    nodes: [
      {"title": 'S', "id": '1', "to": null},
      {
        "title": 'A',
        "id": '2',
        "to": '1',
      },
      {
        "title": 'V',
        "id": '3',
        "to": '1',
      },
      {
        "title": 'K',
        "id": '4',
        "to": '1',
      },
      {
        "title": 'K',
        "id": '5',
        "to": '2',
      },
    ].map((e) => Node(data: e,)).toList(),
    idProvider: (data) => data["id"],
    toProvider: (data) => data["to"],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: OrgChart(
            graph: graph,
            builder: (node, calculatePosition, setState) {
              return Container(
                // width: 100,
                // height: 100,
                color: Colors.red,
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(onPressed: () {
          graph.calculatePosition();
          setState(() {});
        }),
      ),
    );
  }
}

 */
