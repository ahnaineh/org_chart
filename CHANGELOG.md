## 4.0.2
1) Graph not drawn, (recursion issue)

## 4.0.1

1) fix bug when centering the graph and some nodes are hidden.


## 4.0.0+1

1) Edit Readme & Changelog


## 4.0.0

1) Added Dashed Arrow Styles
   - Added 'arrowStyle' to the orgchart widget with 2 options: 'SolidGraphArrow' & 'DashedGraphArrow'
2) Fixed boundries issues sometimes node is out of the boundaries causing unabilty to drag it back or click it
3) Dragging node into a negative position is unallowed now
4) Exposed 'minScale' & 'maxScale' in the orgchart widget to control the zooming scale
5) Graph now will be centered on init and on orientation change.
   (you can disable this on orientation change by setting the new paramater 'center' to false in the function 'switchOrientation')
   using the 'orientation' setter in the controller is now deprecated
   this parameter is also implemented in the 'calculatePosition' function and the default value is true.
6) New method on the controller 'centerChart' to center the chart when wanted.
7) bug fix: unnecessary node index changing when starting to drag a node. It was causing reordering nodes on the same level in a weird/unexpected/unwanted way.
8) Updated example a bit.
9) Removed `ontTap` and `onDoubleTap` from the `OrgChart` widget. Because of these, when a button on the node is pressed, running the callback is delayed, so to remove this delay both of these were removed. You can still add a `GestureDetector` in the builder method to achieve the same functionality.


## 3.1.0

1) Added 'switchOrientation' to controller; automatically switches the set orientation.
2) When using dart```controller.orientation = x``` 'calculatePostion' will be run automatically, updating the chart. You don't need to run calculatePosition for this.
3) Replaced 'offset' with 'spacing' and 'runSpacing' as the 'spacing' is according to the orientation and not fixed to x & y. Now it's working as expected.
4) Extra trees/roots now show aside/below each other rather than showing one only(according to oreintation).
5) Added line radius to leaf nodes. Missed it in the previous version.
5) Added a method 'idSetter' to the controller it's required only if you want to use the function 'removeItem', that's to change the to-id of the subnodes. Either unlinking from the tree, or linking to parent node.
6) Added 'action' attribute to 'removeItem' function to specify the action to be taken on the subnodes of the removed node. Currently these 2 options: 'ActionOnNodeRemoval.unlink' or 'ActionOnNodeRemoval.linkToParent'.


## 3.0.0+1

1) Update Readme


## 3.0.0

1) Under the hood code cleanup.
2) Fixed arrow-spacing relation bug.
3) Added new parameter 'cornerRadius' to the orgchart widget to customize the corner radius of the arrows.
4) Added new parameter 'level' to 'NodeBuilderDetails' that is passed to the builder method to indicate the depth of the node in the tree.
5) Added new parameter 'isTargetSubnode' to 'onDrop' function to indicate if the node is being dropped on a subnode. The checking is now done automatically behind the scenes. If true, do not add the node to the subnodes of the target node, as this will result in crashing the app. You might instead show an alert or ignore this action.
6) Updated the example to reflect this change. And tweaked the style a bit.
7) Dropped 'Graph' class & 'graph' parameter on 'OrgChart' class which were previously deprecated.
8) No more need to call setState after calculatePosition to update the ui, it happens automatically now!
9) Only the first tree will be displayed rather than stacking trees in case of multiple roots in the provided list.


## 2.2.0

1) Bug fix (issue calculating the positions of a one subnode streak)
2) Add orientation (2 supported orientations top to bottom and left to right)
3) adding ability to customize the arrow paint
4) resetting the positions in the example now also changes the orientation from top-to-bottom to left-to-right and vice versa


## 2.1.0

1) added 2 new parameters to the orgchart widget: 'onTap' & 'onDoubleTap'
2) added a new function: 'addItem' to the graph class to make it easier to add an item to the list, instead of the the old way dart`graph.items = graph.items + [newItem]`
3) added a new example to show the new features
4) minor arrow drawing change
5) added a graph method 'uniqueNodeId' auto returns a unique id for a node


## 2.0.1

1) Clean up


## 2.0.0

1) Removed the need to map custom data types to the node class, it's done internally now
And the utility functions now return the data instead of the node
2) The builder method now inputs only a one parameter 'details' instance of new class 'NodeBuilderDetails' which contains the following:
    - data: the data of the node
    - hideNodes: a function to hide the subnodes
    - nodesHidden: a boolean to indicate if the subnodes of the node are hidden
    - beingDragged: a boolean to indicate if the node is being dragged
    - isOverlapped: a boolean to indicate if the node is overlapped by another node
3) Allowed customizing the curve and duration of the animation of resetting the tree postions (look the example)
4) Added docstrings / internal code tweaking


## 1.0.1

No api change


## 1.0.0

First Semi-stable implementation
