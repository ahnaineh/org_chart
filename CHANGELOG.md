## 1.0.0

First Semi-stable implementation


## 1.0.1

No api change


## 2.0.0

1) Removed the need to map custom data types to the node class, it's done internally now
And the utility functions now return the data instead of the node
2) The builder method now inputs only a one parameter 'details' instance of new class 'NodeBuilderDetails' which contains the following:
    - data: the data of the node
    - hideNodes: a function to hide the children of the node
    - nodesHidden: a boolean to indicate if the subnodes of the node are hidden
    - beingDragged: a boolean to indicate if the node is being dragged
    - isOverlapped: a boolean to indicate if the node is overlapped by another node
3) Allowed customizing the curve and duration of the animation of resetting the tree postions (look the example)
4) Added docstrings / internal code tweaking


## 2.0.1

1) Clean up


## 2.1.0

1) added 2 new parameters to the orgchart widget: 'onTap' & 'onDoubleTap'
2) added a new function: 'addItem' to the graph class to make it easier to add an item to the list, instead of the the old way dart`graph.items = graph.items + [newItem]`
3) added a new example to show the new features
4) minor arrow drawing change
5) added a graph method 'uniqueNodeId' auto returns a unique id for a node


## 2.2.0

1) Bug fix (issue calculating the positions of a one subnode streak)
2) Add orientation (2 supported orientations top to bottom and left to right)
3) adding ability to customize the arrow paint
4) resetting the positions in the example now also changes the orientation from top-to-bottom to left-to-right and vice versa