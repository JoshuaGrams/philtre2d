GUI Objects
===========

An alternate attempt at a GUI layout system. Each node has an anchor point
on its parent, a pivot point on itself, and a resize mode to control how it
changes to fit the area it is allocated. Nodes aren't constrained to fit
inside their parent at all, they're just given a width and height (and an
offset for Row/Column nodes).

All Nodes except SpriteNodes generally don't scale, they just change their
width and height. A global scale factor can be passed down the tree, which
will scale local positions, padding, row/column spacing, text size, and the
size of nodes with the "none" resize mode.

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
`parentResized` on this root node (see "node methods" below). Draw your GUI
outside of any camera transforms.

Node Objects
------------

### Node(x, y, angle, w, h, px, py, ax, ay, modeX, modeY, padX, padY)

A basic, invisible, layout node.

_PARAMETERS_
* __x, y__ <kbd>number</kbd> - Local pos. The offset between the node's pivot point on itself and its anchor point on its parent.
* __angle__ <kbd>number</kbd> - Local rotation around the node's pivot point.
* __w, h__ <kbd>number</kbd> - The initial width and height of the node.
* __px, py__ <kbd>number</kbd> - The X and Y of the node's pivot point. From -1 to 1. (0, 0) is centered. (-1, -1) is the top left corner, etc.
* __ax, ay__ <kbd>number</kbd> - The X and Y anchors of the node. From -1 to 1.
* __modeX__ <kbd>string</kbd> - The resize mode for the Node's width. Defaults to 'none'. The available modes are:
	* `none` - Only changes size if the scale factor is changed.
	* `fit` - Resizes proportionally based on the new relative w/h, whichever is smaller.
	* `zoom` - Resizes proportionally based on the new relative w/h, whichever is larger.
	* `stretch` - Stretches each axis separately to fill the same proportion of the available length.
	* `fill` - Stretches each axis separately to fill all available space.
* __modeY__ <kbd>string</kbd> - The resize mode for the Node's height. Defaults to `modeX` or 'none'.
* __padX, padY__ <kbd>number</kbd> - X and Y padding _inside_ the node. Affects the size allocated to its children. You only need to specify `padX` if both axes are the same.

_NODE METHODS_

* __parentResized(designW, designH, newW, newH, scale, ox, oy)__
	* `designW`, `designH` - The original, designed width/height of the parent node (or the screen in the case of a root node).
	* `newW`, `newH` - The new, current width/height of the parent node or screen.
	* `scale` - The scale factor to apply to all child nodes.
	* `ox`, `oy` - _optional_ - An extra position offset. The node will act as if its parent's position was offset by these values. Used by nodes that automatically position multiple child nodes (i.e. Row/Column nodes).

### Slice(image, quad, margins, x, y, angle, w, h, px, py, ax, ay, modeX, modeY)

A 9-slice image node.

_PARAMETERS_
* __image__ <kbd>string | Image</kbd> - An image filepath or Image object.
* __quad__ <kbd>table | Quad</kbd> - _optional_ - A table with four numbers {lt, top, width, height} to define a quad, or a Quad object, if the image used is part of a texture atlas.
* __margins__ <kbd>table</kbd> - The margins for the image slices, measured inward from the edges. Can be a table with one number, if all the margins are equal, two numbers if its symmetrical on each axis, or four numbers if they are all different.

### Text(text, font, x, y, angle, w, px, py, ax, ay, hAlign, modeX, modeY)

A text node. The text is wrapped to fit inside the specified width, `w`. The height of the node is automatically determined by the size of the font and the number of lines that the text wraps to.

_PARAMETERS_
* __text__ <kbd>string</kbd> - The text to be displayed.
* __font__ <kbd>table</kbd> - Must be a table: `{filename, size}`.
* __hAlign__ <kbd>string</kbd> - _optional_ - How the text is aligned within the node's width. Can be: "center", "left", "right", or "justify". Defaults to "left".

### Sprite(image, x, y, angle, sx, sy, color, px, py, ax, ay, modeX, modeY)

A basic image node. Scales the image to fit its allocated width & height.

_PARAMETERS_
* __image__ <kbd>string | Image</kbd> - An image filepath or Image object.
* __color__ <kbd>table</kbd> - _optional_ - The image multiply color. Defaults to opaque white: {1, 1, 1, 1}.

### Row(spacing, homogeneous, dir, x, y, angle, w, h, px, py, ax, ay, modeX, modeY, padX, padY)

An invisible node that automatically arranges its children in a horizontal row.

_PARAMETERS_
* __spacing__ <kbd>number</kbd> - _optional_ - The amount of extra space to allocate between children (but not at the ends). Defaults to 0.
* __homogeneous__ <kbd>bool</kbd> - _optional_ - If `true`, divides up the available space equally between all children. If `false`, allocates each child space based on its design width and allocates any extra space between any children with a truthy `isGreedy` property (or leaves it empty if there are none). Defaults to false.
* __dir__ <kbd>number</kbd> - _optional_ - -1 or 1. Controls which end of the row the children are aliged from. If -1, the first child we be at the left end of the Row and subsequent children will be space out to the right. If +1, the first child will be at the _right_ end of the Row, with subsequent children to the left. If it's a fraction, it will multiply how much of the Row's length is used. Defaults to -1 (left end).

### Column(spacing, homogeneous, dir, x, y, angle, w, h, px, py, ax, ay, modeX, modeY, padX, padY)

The same as Row only vertical.

### Mask(stencilFunc, x, y, angle, w, h, px, py, ax, ay, modeX, modeY, padX, padY)

An invisible node that masks out (stencils) the rendering of its children. On init it sets a `.maskObject` property to itself on all of its children (recursively). Any child nodes added after init should have this property set manually, or call `Mask.setMaskOnChildren` on the mask node.

_PARAMETERS_
* __stencilFunc__ <kbd>function</kbd> - _optional_ - Should be a function that draws a shape for the stencil. Is given one argument: `self`. By default it draws a rectangle with the inner width/height of the node.
