
import 'package:flutter/material.dart';

class Node<E> {
  Offset position;
  E data;
  bool hideNodes;

  Node({
    required this.data,
    this.position = Offset.zero,
    this.hideNodes = false,
  });

  Offset distance(Node node) => node.position - position;
}
