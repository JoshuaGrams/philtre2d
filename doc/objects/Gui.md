# GUI Objects

A set of objects for GUI layout. Uses a base 'Node' class that has a pivot point on itself, an anchor point on its parent, and resize modes for each axis to control how it changes to fit the area it is allocated. Nodes aren't constrained to fit inside their parent at all, they're just given a width and height (and an offset for Row/Column nodes).

Nodes do not scale, they just change their width and height. A global scale factor can be passed down the tree, which will scale padding, row/column spacing, text size, and 9-Slice margin sizes.

## Basic Usage

Nodes inherit Object and go in the scene-tree. Expected usage is to have a single Node at the root of your scene-tree to fill the screen and be the parent for the rest of your GUI. On love.resize(), call `allocate` on this root node (see "node methods" below) with the window size. Draw your GUI outside of any camera transforms.

```lua
-- Example including scene-tree setup and debug drawing:
require "philtre.init"

local gui = require "philtre.objects.gui.all"
-- Gives you a table with `Alloc` and all the gui node objects:
-- Node, Slice, Text, Sprite, Row, Column, and Mask.

local layers = {
	gui = { "gui" },
}
local debugLayer = "debug"

local scene
local guiRoot

function love.load()
	scene = SceneTree(layers, "gui")
	-- Add a node that will fill the window:
	guiRoot = scene:add( gui.Node(100, "%", 100, "%") )
	local w, h = love.graphics.getDimensions()
	guiRoot:allocate(0, 0, w, h, 1)
end

function love.resize(w, h)
	guiRoot:allocate(0, 0, w, h, 1)
end

function love.draw()
	scene:draw("gui")
	guiRoot:callRecursive(true, "debugDraw")
end
```

## Node Objects

### Node(w, modeX, h, modeY, pivot, anchor, padX, padY)

A basic, invisible, layout node.

_PARAMETERS_
* __w__ <kbd>number</kbd> - The parameter to determine the node's width.
* __modeX__ <kbd>string</kbd> - The resize mode for the node's width. Defaults to 'pixels'. The available modes are:
	* 'pixels' - `w` is a fixed number of pixels.
	* 'units' - `w` is multiplied by the allocation `scale`.
	* 'percentw' - Percent of parent width. `w` is divided by 100 and multiplied by the parent's width.
	* 'percenth' - Percent of parent height. `w` is divided by 100 and multiplied by the parent's height.
	* 'aspect' - `w` is an aspect ratio (w/h) to be multiplied with the node's current height. Both `modeX` and `modeY` can't be set to 'aspect' at the same time, since the result is based on the size on the other axis.
	* 'relative' - `w` is a number of pixels added to the parent's width.

	There are also the following mode shortcut strings that can be used:

	* 'px' = 'pixels'
	* 'u' = 'units'
	* '%' = 'percentw' for `modeX` or 'percenth' for `modeY`.
	* '%w' = 'percentw'
	* '%h' = 'percenth'
	* 'rel' = 'relative'
	* '+' = 'relative'

	Nodes with sizes that are based on parent sizes (percentw/h and relative modes) will need to have a 'desired' size set (with Node:desire()) for the relevant axis before they can be controlled by Row and Column nodes. If not, they will simply be allocated the full size of the Row or Column. With other modes, the desired width and height will be set to match (though Node:desire() can still be used to set a separate desired size).
* __h__ <kbd>number</kbd> - The parameter to determine the node's height.
* __modeY__ <kbd>string</kbd> - The resize mode for the node's height. Defaults to `modeX` or 'pixels'.
* __pivot__ <kbd>string | table</kbd> - A cardinal direction signifying the node's origin/pivot point. "N", "NE", "E" "SE", "S", "SW", "W", "NW", or "C" (centered). Can be uppercase or lowercase (but not a mixture). Defaults to "C". Or, to set an arbitrary pivot, can be a table with two elements.
* __anchor__ <kbd>string | table</kbd> - A cardinal direction signifying the node's anchor point inside its allocated area. Defaults to "C". Or, to set an arbitrary anchor, can be a table with two elements..
* __padX, padY__ <kbd>number</kbd> - X and Y padding _inside_ the node. Affects the size allocated to its children. `padY` will be made equal to `padX` if it is not also specified.

_NODE METHODS_

* __request()__ - Gets a table with the node's requested width & height.

* __desire( [w], [h] )__ - Set the node's desired width and/or height, to be used by parent container nodes (Row or Column).

* __allocate( x, y, w, h, scale )__ - Refresh the node within the specified space allocation.

* __allocateChild( child )__ - Update the allocation of a single child.
	* `child` - The child object to re-allocate.

* __allocateChildren()__ - Update the allocation of all children.

* __setSize( w, h )__ - Set the size of the node.
	* `inDesignCoords` - If the width & height are to set the original, unscaled values of the node, rather than it's current, scaled values.

* __setPos( x, y, [isRelative] )__ - Set the local position of the node—the offset between it's pivot and anchor points.

* __setCenterPos( x, y )__ - Set the position of the center of a node, regardless of it's pivot and anchor, using a position local to its parent node. For example:

```lua
function love.mousepressed(x, y, button, isTouch)
	if button == 1 then
		local lx, ly = parentNode:toLocal(x, y)
		exampleNode:setCenterPos(lx, ly)
	end
end
```

* __setAngle( a )__ - Set the angle of the node.

* __setOffset( [x], [y], [isRelative] )__ - Set the offset of the node's child allocation rect.
	* `isRelative` - If `x` and `y` are relative/additive rather than absolute.

* __setPivot( [x], [y] )__ - Set the node's pivot: the point relative to its own width/height that represents its origin.
	* `x` - Can be a cardinal direction string (capitalized or not): "NW", "C", "E", etc., or a table with two elements (ex: {1, 0}), in which case the `y` argument is ignored. Otherwise, the x and y pivots are only set when they are specified.

* __setAnchor( [x], [y] )__ - Set the node's anchor: the point on its parent that it places itself relative to.
	* `x` - Can be a cardinal direction string (capitalized or not): "NW", "C", "E", etc., or a table with two elements (ex: {1, 0}), in which case the `y` argument is ignored. Otherwise, the x and y anchors are only set when they are specified.

* __setPad( [x], [y] )__ - Set the node's padding. Padding is always stored un-scaled. Each argument is ignored if not specified.

* __setMode( [x], [y] )__ - Set the resize mode(s) of the node. Each argument is ignored if not specified.

* __setGreedy( isGreedy )__ - Set the 'isGreedy' property of the node for a parent Row or Column node to use. Greedy children will be allocated a proportional share of any extra space inside the Row/Column.

> The setter methods all return `self`, so they can be chained together.

### Slice(image, quad, margins, w, modeX, h, modeY, pivot, anchor, padX, padY)

A 9-slice image node.

_PARAMETERS_
* __image__ <kbd>string | Image</kbd> - An image filepath or Image object.
* __quad__ <kbd>table | Quad</kbd> - _optional_ - A table with four numbers {lt, top, width, height} to define a quad, or a Quad object, if the image used is part of a texture atlas.
* __margins__ <kbd>table</kbd> - The margins for the image slices, measured inward from the edges. Can have either one, two, or four elements:
	* `{m}` - All margins are equal.
	* `{x, y}` - Margins on each axis are equal.
	* `{lt, rt, top, bot}` - Each margin is set separately.

### Text(text, font, w, modeX, pivot, anchor, hAlign, isWrapping)

A text node. By default the text stays in a single line, but it can be set to wrap within the node's width. The height of the node is automatically determined by the size of the font and the number of lines that the text wraps to.

> NOTE: Text always wraps if `hAlign` is set to "justify", since it doesn't make much sense otherwise.

_PARAMETERS_
* __text__ <kbd>string</kbd> - The text to be displayed.
* __font__ <kbd>table</kbd> - Must be a table: `{filename, size}`.
* __hAlign__ <kbd>string</kbd> - _optional_ - How the text is aligned within the node's width. Can be: "center", "left", "right", or "justify". Defaults to "left".
* __isWrapping__ <kbd>bool</kbd> - _optional_ - Set to `true` to wrap the text within the nodes width, `w`. Text always wraps regardless of this setting if `hAlign` is set to "justify".

_TEXT METHODS_
* __setAlign( hAlign )__ - Sets the horizontal alignment of the text. Must be "center", "left", "right", or "justify".

* __setWrap( isWrapping )__ - Sets wrapping enabled or disabled. Text always wraps regardless of this setting if `hAlign` is set to "justify".

### Sprite(image, color, w, modeX, h, modeY, pivot, anchor, padX, padY)

A basic image node. Scales the image to fit its allocated width & height.

_PARAMETERS_
* __image__ <kbd>string | Image</kbd> - An image filepath or Image object.
* __color__ <kbd>table</kbd> - _optional_ - The image multiply color. Defaults to opaque white: {1, 1, 1, 1}.

### Row(w, modeX, h, modeY, pivot, anchor, padX, padY, spacing, isEven, isReversed)

An invisible node that automatically arranges its children in a horizontal row. If any child does not have a desired width set, then it will be excluded from the row layout and allocated the full inner size of the Row node. When you add or remove children you can refresh the arrangement with: `self:allocateChildren()`.

_PARAMETERS_
* __spacing__ <kbd>number</kbd> - _optional_ - The amount of extra space to allocate between children (but not at the ends). Defaults to 0.
* __isEven__ <kbd>bool</kbd> - _optional_ - If `true`, divides up the available space equally between all children. If `false`, allocates each child space based on its desired width and allocates any extra space between any children with a truthy `isGreedy` property (or leaves it empty if there are none). Defaults to false (uneven).
* __isReversed__ <kbd>bool</kbd> - _optional_ - If true, the child nodes will be arranged from right-to-left (from the right end of the node) instead of the default left-to-right.

_ROW/COLUMN METHODS:_
* __setSpacing( spacing )__ - Set the number of pixels of spacing to add between each child node. Spacing is multiplied by allocation scale.

* __setEven( isEven )__ - Set the `isEven` property of the Row.

* __setReversed( isReversed )__ - Set the `isReversed` property of the Row.

### Column(w, modeX, h, modeY, pivot, anchor, padX, padY, spacing, isEven, isReversed)

The same as Row only vertical. The 'isReversed' setting will cause the children to be arranged from bottom to top.

### Mask(stencilFunc, w, modeX, h, modeY, pivot, anchor, padX, padY)

An invisible node that masks out (stencils) the rendering of its children. On init it sets a `._mask` property to itself on all of its children (recursively). Any child nodes added after init should have this property set manually, or call `Mask.setMaskOnChildren` on the mask node.

_PARAMETERS_val
* __stencilFunc__ <kbd>function</kbd> - _optional_ - Should be a function that draws a shape for the stencil. Must be an anonymous function taking no arguments. By default it draws a rectangle with the inner width/height of the node.

### Allocation

A helper used internally for storing GUI allocations.

```lua
local alloc = gui.Alloc(x, y, w, h, [scale])
```
_ALLOCATION METHODS_

* __pack(x, y, w, h, scale)__ - Set all fields of the allocation at once. All arguments are required

* __unpack()__ - Returns all fields of the allocation, in the same order they are given to pack().

* __equals(x, y, w, h, scale)__ - Check if the Alloc's properties are the same as all of those given.
