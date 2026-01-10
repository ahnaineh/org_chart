import 'package:flutter/rendering.dart';

class GraphParentData extends ContainerBoxParentData<RenderBox> {
  GraphParentData({
    this.nodeId = '',
    this.desiredOffset = Offset.zero,
    this.isHitTestable = true,
  });

  String nodeId;
  Offset desiredOffset;

  /// Allows nodes to remain in the tree but opt out of hit testing.
  bool isHitTestable;

  @override
  String toString() => '${super.toString()}; nodeId=$nodeId';
}
