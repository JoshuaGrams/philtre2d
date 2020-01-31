GUI Objects
===========

An alternate attempt at a GUI layout system. Each node has an anchor point
on its parent, a pivot point on itself, and a resize mode to control how it
changes to fit the area it is allocated. Nodes aren't constrained to fit
inside their parent at all, they're just given a width and height (and an
offset for Row/Column nodes).

All Nodes except SpriteNodes generally don't scale, they just change their
width and height. A global scale factor can be passed down the tree, which
will scale local positions, padding, text size, and the size of nodes with
the "none" resize mode.

Basic Usage
-----------

```lua
local gui = require "philtre.gui.all"
-- Gives you a table with all the gui node objects:
-- Node, Slice, Text, Sprite, Row, Column, and Mask.
```

Nodes are all normal Objects. It's easiest if you start with a root node
with an anchor of (0, 0) and pivot at (-1, -1) (top left corner) so its
children will be centered on the screen by default. On love.resize(), call
`parentResized` on this root node (see "node methods" below). Draw your GUI outside of any camera
transforms.

Node Objects
------------

### Node(x, y, angle, w, h, ax, ay, px, py, resizeMode, padX, padY)

A basic, invisible, layout node.

_PARAMETERS_
* __x, y__ <kbd>number</kbd> - Local pos. The offset between the node's pivot point on itself and its anchor point on its parent.
* __angle__ <kbd>number</kbd> - Local rotation around the node's pivot point.
* __w, h__ <kbd>number</kbd> - The initial width and height of the node.
* __ax, ay__ <kbd>number</kbd> - The X and Y anchors of the node. From -1 to 1. (0, 0) is centered. (-1, -1) is the top left corner, etc.
* __px, py__ <kbd>number</kbd> - The X and Y of the node's pivot point. From -1 to 1.
* __resizeMode__ <kbd>string | table</kbd> - A single string if both axes' modes are the same, or a table with two strings if they are different. The available modes are:
	* `none` - Only changes size if the scale factor is changed.
	* `fit` - Resizes proportionally based on the new relative w/h, whichever is smaller.
	* `zoom` - Resizes proportionally based on the new relative w/h, whichever is larger.
	* `stretch` - Stretches each axis separately to fill the same proportion of the available length.
	* `fill` - Stretches each axis separately to fill all available space.
* __padX, padY__ <kbd>number</kbd> - X and Y padding _inside_ the node. Affects the size allocated to its children. You only need to specify `padX` if both axes are the same.

_NODE METHODS_

* __parentResized(originalW, originalH, newW, newH, scale, ox, oy)__
	* `originalW`, `originalH` - The original, designed, width/height of the parent node (or the screen in the case of a root node).
	* `newW`, `newH` - The new, current width/height of the parent node or screen.
	* `scale` - The scale factor to apply to all child nodes.
	* `ox`, `oy` - _optional_ - An extra position offset. The node will act as if its parent's position was offset by these values. Used by nodes that automatically position multiple child nodes (i.e. Row/Column nodes).

### Slice(image, quad, margins, x, y, angle, w, h, ax, ay, px, py, resizeMode)

A 9-slice image node.

_PARAMETERS_
* __image__ <kbd>string | Image</kbd> - An image filepath or Image object.
* __quad__ <kbd>table | Quad</kbd> - _optional_ - A table with four numbers {lt, top, width, height} to define a quad, or a Quad object, if the image used is part of a texture atlas.
* __margins__ <kbd>table</kbd> - The margins for the image slices, measured inward from the edges. Can be a table with one number, if all the margins are equal, two numbers if its symmetrical on each axis, or four numbers if they are all different.

### Text(text, font, x, y, angle, w, ax, ay, px, py, hAlign, resizeMode)

A text node. The text is wrapped to fit inside the specified width, `w`. The height of the node is automatically determined by the size of the font and the number of lines that the text wraps to.

_PARAMETERS_
* __text__ <kbd>string</kbd> - The text to be displayed.
* __font__ <kbd>table</kbd> - Must be a table: `{filename, size}`.
* __hAlign__ <kbd>string</kbd> - _optional_ - How the text is aligned within the node's width. Can be: "center", "left", "right", or "justify". Defaults to "left".

### Sprite(image, x, y, angle, sx, sy, color, ax, ay, px, py, resizeMode)

A basic image node. Scales the image to fit its allocated width & height.

_PARAMETERS_
* __image__ <kbd>string | Image</kbd> - An image filepath or Image object.
* __color__ <kbd>table</kbd> - _optional_ - The image multiply color. Defaults to opaque white: {1, 1, 1, 1}.

### Row(spacing, homogeneous, children, x, y, angle, w, h, ax, ay, px, py, resizeMode, padX, padY)

An invisible node that automatically arranges its children in a horizontal row.

_PARAMETERS_
* __spacing__ <kbd>number</kbd> - _optional_ - The amount of extra space to allocate between children (but not at the ends). Defaults to 0.
* __homogeneous__ <kbd>bool</kbd> - _optional_ - If `true`, divides up the available space equally between all children. If `false`, allocates each child space based on its original width and allocates any extra space between `greedy` children (or leaves it empty if there are none). Defaults to false.
* __children__ <kbd>table</kbd> - _optionoal_ - A list of settings for each child that should be arranged in the row. Each item should have the following format: {`obj`, `dir`, `isGreedy`, `index`}. Any children in the scene-tree that are not indicated in the list will be allocated the full inner width/height of the Row, like a normal Node.
	* `obj` - The child object. This can also be a number, in which case the Row's child of that index will be used (if it exists).
	* `dir` - _optional_ - Which side of the Row to align the child to: "start" or "end" (defaults to "start"/left).
	* `isGreedy` - _optional_ - Whether this child wants extra space or not. Extra space is divided up between greedy children proportional to their original width. Irrelevant for homogeneous rows. Defaults to false.
	* `index` - _optional_ - An override for the list index to place this child at. The child with the lowest index is placed closest to the end of the row (whichever end its `dir` is set to).

### Column(spacing, homogeneous, children, x, y, angle, w, h, ax, ay, px, py, resizeMode, padX, padY)

The same as Row only vertical.

### Mask(stencilFunc, x, y, angle, w, h, ax, ay, px, py, resizeMode, padX, padY)

An invisible node that masks out (stencils) the rendering of its children. On init it sets a `.maskObject` property to itself on all of its children (recursively). Any child nodes added after init should have this property set manually, or call `Mask.setMaskOnChildren` on the mask node.

_PARAMETERS_
* __stencilFunc__ <kbd>function</kbd> - _optional_ - Should be a function that draws a shape for the stencil. Is given one argument: `self`. By default it draws a rectangle with the inner width/height of the node.
