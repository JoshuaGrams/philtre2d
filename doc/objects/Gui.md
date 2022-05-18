# GUI Objects

An alternate attempt at a GUI layout system. Each node has an anchor point on its parent, a pivot point on itself, and a resize mode to control how it changes to fit the area it is allocated. Nodes aren't constrained to fit inside their parent at all, they're just given a width and height (and an offset for Row/Column nodes).

All Nodes except SpriteNodes generally don't scale, they just change their width and height. A global scale factor can be passed down the tree, which will scale local positions, padding, row/column spacing, text size, Slice image size, and the size of nodes with the "none" resize mode.

## Basic Usage

```lua
-- Example including scene-tree setup and debug drawing:
require "philtre.init"

local gui = require "philtre.objects.gui.all"
-- Gives you a table with `Rect` and all the gui node objects:
-- Node, Slice, Text, Sprite, Row, Column, and Mask.

local layers = {
	debug = { "debug" },
	world = { "default" },
}
local debugLayer = "debug"

local scene
local guiRoot
local screenAlloc = gui.Rect(0, 0, 800, 600)

function love.load()
	scene = SceneTree(layers)

	guiRoot = scene:add( gui.Node(800, 600, "NW", "C", "fill") )
	guiRoot:allocate(screenAlloc)
end

function love.resize(w, h)
	screenAlloc.w, screenAlloc.h = w, h
	guiRoot:allocate(screenAlloc)
end

function love.draw()
	scene:updateTransforms()
	scene:draw("world")
	scene:callRecursive("debugDraw", debugLayer)
	scene:draw("debug")
	scene.draw_order:clear(debugLayer)
end
```

Nodes inherit Object and go in the scene-tree. Expected usage is to have a single Node at the root of your scene-tree to fill the screen and be the parent for the rest of your GUI. Give your root node the pivot: "NW", anchor: "C", and mode: "fill" so its children will be centered on the screen by default. On love.resize(), call `allocate` on this root node (see "node methods" below). Draw your GUI outside of any camera transforms.

### Rect

A helper for making tables for GUI allocations.

```lua
local rect = gui.Rect(x, y, w, h)
```

## Node Objects

### Node(w, h, pivot, anchor, modeX, modeY, padX, padY)

A basic, invisible, layout node.

_PARAMETERS_
* __w, h__ <kbd>number</kbd> - The initial width and height of the node.
* __pivot__ <kbd>string</kbd> - A cardinal direction signifying the node's origin/pivot point. "N", "NE", "E" "SE", "S", "SW", "W", "NW", or "C" (centered). Can be uppercase or lowercase (but not a mixture). Defaults to "C". To set arbitrary pivot points, use Node.pivot().
* __anchor__ <kbd>string</kbd> - A cardinal direction signifying the node's anchor point inside its allocated area. Defaults to "C". To set arbitrary anchor points, use Node.anchor().
* __modeX__ <kbd>string</kbd> - The resize mode for the node's width. Defaults to 'none'. The available modes are:
	* `none` - Only changes size if the scale factor is changed.
	* `fit` - Resizes proportionally based on the new relative w/h, whichever is smaller.
	* `cover` - Resizes proportionally based on the new relative w/h, whichever is larger.
	* `stretch` - Stretches each axis separately to fill the same proportion of the available length.
	* `fill` - Stretches each axis separately to fill all available space.
* __modeY__ <kbd>string</kbd> - The resize mode for the node's height. Defaults to `modeX` or 'none'.
* __padX, padY__ <kbd>number</kbd> - X and Y padding _inside_ the node. Affects the size allocated to its children. You only need to specify `padX` if both axes are the same.

_NODE METHODS_

* __request()__ - Gets a table with the node's requested width & height.


* __allocate( [alloc], [forceUpdate] )__ - Refresh the node within the specified space allocation.
	* `alloc` - The allocation table in the following format: `{ x=, y=, w=, h=, designW=, designH=, scale= }`. If unspecified, the last known allocation is used.
	* `forceUpdate` - To force the child and all descendants to re-allocate even if they haven't changed.


* __allocateChild( child, [forceUpdate] )__ - Update the allocation of a single child.
	* `child` - The child object to re-allocate.


* __allocateChildren( [forceUpdate] )__ - Update the allocation of all children.


* __size( w, h, [inDesignCoords] )__ - Set the size of the node.
	* `inDesignCoords` - If the width & height are to set the original, unscaled values of the node, rather than it's current, scaled values.


* __setPos( x, y, [inDesignCoords], [isRelative] )__ - Set the local position of the node—the offset between it's pivot and anchor points.

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


* __offset( [x], [y], [isRelative] )__ - Set the offset of the node's allocation rect.
	* `isRelative` - If `x` and `y` are relative/additive rather than absolute.


* __pivot( [x], [y] )__ - Set the node's pivot: the point relative to its own width/height that represents its origin.
	* `x` - Can be a cardinal direction string (capitalized or not): "NW", "C", "E", etc., in which case the `y` argument is ignored. Otherwise, the x and y pivots are only set when they are specified.


* __anchor( [x], [y] )__ - Set the node's anchor: the point on its parent that it places itself relative to.
	* `x` - Can be a cardinal direction string (capitalized or not): "NW", "C", "E", etc., in which case the `y` argument is ignored. Otherwise, the x and y anchors are only set when they are specified.


* __pad( [x], [y] )__ - Set the node's padding. Padding is always stored un-scaled. `x` defaults to `0`. `y` defaults to `x` or `0`.


* __mode( [x], [y] )__ - Set the resize mode(s) of the node. `x` defaults to `'none'`. `y` defaults to `x` or `'none'`.

> The setter methods all return `self`, so they can be chained together.


### Slice(image, quad, margins, w, h, pivot, anchor, modeX, modeY)

A 9-slice image node.

_PARAMETERS_
* __image__ <kbd>string | Image</kbd> - An image filepath or Image object.
* __quad__ <kbd>table | Quad</kbd> - _optional_ - A table with four numbers {lt, top, width, height} to define a quad, or a Quad object, if the image used is part of a texture atlas.
* __margins__ <kbd>table</kbd> - The margins for the image slices, measured inward from the edges. Can have either one, two, or four elements:
	* `{m}` - All margins are equal.
	* `{x, y}` - Margins on each axis are equal.
	* `{lt, rt, top, bot}` - Each margin is set separately.

### Text(text, font, w, pivot, anchor, hAlign, modeX, isWrapping)

A text node. By default the text stays in a single line, but it can be set to wrap within the node's width. The height of the node is automatically determined by the size of the font and the number of lines that the text wraps to.

> NOTE: Text always wraps if `hAlign` is set to "justify", since it doesn't make much sense otherwise.

_PARAMETERS_
* __text__ <kbd>string</kbd> - The text to be displayed.
* __font__ <kbd>table</kbd> - Must be a table: `{filename, size}`.
* __hAlign__ <kbd>string</kbd> - _optional_ - How the text is aligned within the node's width. Can be: "center", "left", "right", or "justify". Defaults to "left".
* __isWrapping__ <kbd>bool</kbd> - _optional_ - Set to `true` to wrap the text within the nodes width, `w`. Text always wraps regardless of this setting if `hAlign` is set to "justify".

_TEXT METHODS_
* __align( hAlign )__ - Sets the horizontal alignment of the text. Must be "center", "left", "right", or "justify".

* __wrap( isWrapping )__ - Sets wrapping enabled or disabled. Text always wraps regardless of this setting if `hAlign` is set to "justify".

### Sprite(image, sx, sy, color, pivot, anchor, modeX, modeY)

A basic image node. Scales the image to fit its allocated width & height.

_PARAMETERS_
* __image__ <kbd>string | Image</kbd> - An image filepath or Image object.
* __color__ <kbd>table</kbd> - _optional_ - The image multiply color. Defaults to opaque white: {1, 1, 1, 1}.

### Row(spacing, homogeneous, dir, w, h, pivot, anchor, modeX, modeY, padX, padY)

An invisible node that automatically arranges its children in a horizontal row. When you add or remove children you can refresh the arrangement with: `self:allocateChildren()`.

_PARAMETERS_
* __spacing__ <kbd>number</kbd> - _optional_ - The amount of extra space to allocate between children (but not at the ends). Defaults to 0.
* __homogeneous__ <kbd>bool</kbd> - _optional_ - If `true`, divides up the available space equally between all children. If `false`, allocates each child space based on its design width and allocates any extra space between any children with a truthy `isGreedy` property (or leaves it empty if there are none). Defaults to false.
* __dir__ <kbd>number</kbd> - _optional_ - -1 or 1. Controls which end of the row the children are aliged from. If -1, the first child we be at the left end of the Row and subsequent children will be space out to the right. If +1, the first child will be at the _right_ end of the Row, with subsequent children to the left. If it's a fraction, it will multiply how much of the Row's length is used. Defaults to -1 (left end).

### Column(spacing, homogeneous, dir, w, h, pivot, anchor, modeX, modeY, padX, padY)

The same as Row only vertical.

### Mask(stencilFunc, w, h, pivot, anchor, modeX, modeY, padX, padY)

An invisible node that masks out (stencils) the rendering of its children. On init it sets a `.maskObject` property to itself on all of its children (recursively). Any child nodes added after init should have this property set manually, or call `Mask.setMaskOnChildren` on the mask node.

_PARAMETERS_
* __stencilFunc__ <kbd>function</kbd> - _optional_ - Should be a function that draws a shape for the stencil. Must be an anonymous function taking no arguments. By default it draws a rectangle with the inner width/height of the node.

_MASK METHODS_
* __setOffset( [x], [y], [isRelative] )__ - Sets the offset on all child nodes.
