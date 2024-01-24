
import 'package:flutter/material.dart';

/// The main class that contains the data, position, and wether to show subnodes or not.
class Node<E> {
  /// The position of the node in the graph
  Offset position;
  /// The data that the node containsm such as the id, to, title, etc.
  /// This is the data that you provide in the items list and you can use to build the node
  E data;
  /// Whether to show the subnodes or not
  bool hideNodes;


  Node({
    required this.data,
    this.position = Offset.zero,
    this.hideNodes = false,
  });

  /// The distance between this node and an input node
  Offset distance(Node node) => node.position - position;
}
