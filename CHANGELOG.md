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