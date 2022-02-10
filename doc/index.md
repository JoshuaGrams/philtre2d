Philtre 2D
==========

Download and install [Löve2D](https://love2d.org/). See also: [Löve2D Getting Started](https://love2d.org/wiki/Getting_Started).

In your desired project folder, create a git repository:

	git init

Add to your git project as a submodule:

	git submodule add -b master https://github.com/JoshuaGrams/philtre2d.git philtre

This will produce a .gitmodules file (if you didn't already have one) and a `philtre` directory (whose SHA-1 hash won't be a hash of the directory, but will point to Philtre's HEAD).  Commit these two entries to your project repository.

Fetch upstream engine changes with:

	git submodule update --remote --merge

This will update `philtre` to point to the new upstream HEAD, and you'll need to commit that change to your project.

-----

Minimal usage / "hello world" example:

```lua
	require 'philtre.init'  -- Load all engine components into global variables.
	local scene

	function love.load()
		scene = SceneTree()
		local t = Text("hello world", love.graphics.newFont())
		scene:add(t)
	end

	function love.update(dt)
		scene:update(dt)
	end

	function love.draw()
		scene:updateTransforms()
		scene:draw()
	end
```

Engine
------

* [Scene Tree](engine/scene-tree.md) - Handles object collections and transforms.

* [Draw Order](engine/draw-order.md) - Cooperates with the scene graph to draw objects by depth or by layer, for cases where drawing them in order of scene graph traversal isn't sufficient.

* [Input](engine/input.md) - Bind physical axes and buttons to form game input axes and buttons.

* [Matrix](engine/matrix.md) - Transformations (rotate, scale, skew, translate) represented as 3x3 matrices (2D homogeneous coordinates).

* [Physics](engine/physics.md) - Helpers for managing named categories, and doing world queries(raycasts, etc.).

* [New](engine/new.md) - A tiny helper module for loading and caching assets.

* [Scripts](engine/scripts.md) - Optional script system for objects in the tree.

Objects
-------
_Required arguments in **bold-italic**._

* [Body](objects/Body.md) - Physics body object.
	* **Body(** **_type_**, x, y, angle, **_shapes_**, prop **)**
* [Camera](objects/Camera.md) - Camera object.
	* **Camera(** x, y, angle, zoom_or_area, scale_mode, fixed_aspect_ratio, inactive **)**
* [Object](objects/Object.md) - Base 'game object' class.
	* **Object(** x, y, angle, sx, sy, kx, ky **)**
* Sprite - Object containing an image.
	* **Sprite(** **_image_**, x, y, angle, sx, sy, color, ox, oy, kx, ky **)**
	* `image` can be either a string (filename) or a love2d Texture object (image or canvas).
* Quad - Object containing a sub-image (for use with sprite sheets).
	* **Quad(** **_image_**, **_quad_**, x, y, angle, sx, sy, color, ox, oy, kx, ky **)**
	* As above, `image` can be a string (filename) or an image.
	* `quad` can be a table (`{x, y, w, h}`) or a quad created with `love.graphics.newQuad`).
* Text - Object for rendering text. No fancy scaling.
	* **Text(** **_text_**, **_font_**, x, y, angle, wrap_limit, align, sx, sy, kx, ky **)**
	* `font` can be a table `{filename, size}` or an existing font object.
	* `align` is a string: one of `left`, `center`, `right`, or `justify`.
* [World](objects/World.md) - Object with its own physics world and callback handlers.
	* **World(** xg, yg, sleep, disableBegin, disableEnd, disablePre, disablePost **)**

* [Layout Objects](objects/Layout.md) - GUI helpers for laying out boxes.

* [GUI Objects](objects/Gui.md) - Alternate GUI layout objects.

Libraries
---------

Useful modules that were written by other people or just aren't required by the engine itself.

* [Testing](lib/simple-test.md) - A simple test-runner.
* [Math Patch](lib/math-patch.md) - Patches some convenient functions into the default `math` library.
* [Vec2 (x,y)](lib/vec2xy.md) - Vector2 operations using only x and y numbers, not tables or userdata.
* [Flux](https://github.com/rxi/flux) - rxi's tweening lib with some [modifications](lib/flux-modifications.md).

Contributors
------------

Joshua Grams <josh@qualdan.com>
Ross Grams <ross.grams@gmail.com>

Coding conventions are in the [guide for contributors](contributing.md).

Todo
----

* Improve coverage of automated tests.
* Work on editor: https://github.com/rgrams/editor.
* Particle Emitter.
* Finish and test box-model GUI system?
* Physics Joint object?
