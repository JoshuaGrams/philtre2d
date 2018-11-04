Philtre 2D
==========

Add to your git project as a submodule:

	git submodule add -b master https://github.com/JoshuaGrams/philtre2d.git philtre

This will produce a .gitmodules file (if you didn't already have one) and a `philtre` directory (whose SHA-1 hash won't be a hash of the directory, but will point to Philtre's HEAD).  Commit these two entries to your project repository.

Huh. Maybe you also need:

	cd philtre
	git branch -u origin/master master

Does that help?

Fetch upstream engine changes with:

	git submodule update --remote

This will update `philtre` to point to the new upstream HEAD, and you'll need to commit that change to your project.

-----

Minimal usage:

	require 'philtre.init'  -- Load all engine components into global variables.

	function love.load()
		drawOrder = DrawOrder({'default_layer'})
		scene.init(drawOrder)
	end

	function love.update(dt)
		scene.update(dt)
	end

	function love.draw()
		drawOrder:draw()
	end


Engine
------

* [Scene Tree](engine/scene-tree.md) - Handles object collections and transforms.

* [Draw Order](engine/draw-order.md) - Cooperates with the scene graph to draw objects by depth or by layer, for cases where drawing them in order of scene graph traversal isn't sufficient.

* [Input](engine/input.md) - Bind physical axes and buttons to form game input axes and buttons.

* [Matrix](engine/matrix.md) - Transformations (rotate, scale, skew, translate) represented as 3x3 matrices (2D homogeneous coordinates).

* [Physics](engine/physics.md) - Some physics utility functions.  For now, manages named collision groups. TODO: raycasts, point checks.

Objects
-------

* [Body](objects/Body.md) - Physics body object.
	* `Body(type, x, y, angle, shapes, prop, ignore_parent_transform)`
* [Camera](objects/Camera.md) - Camera object.
	* `Camera(x, y, angle, zoom_or_area, scale_mode, fixed_aspect_ratio, inactive)`
* [Object](objects/Object.md) - Base 'game object' class.
	* `Object(x, y, angle, sx, sy, kx, ky)`
* Sprite - Object containing an image.
	* `Sprite(image, x, y, angle, sx, sy, color, ox, oy, kx, ky)`
* Text - Object for rendering text. No fancy scaling.
	* `Text(x, y, angle, text, font_filename, font_size, wrap_limit, align, sx, sy, kx, ky)`
* [World](objects/World.md) - Object with its own physics world and callback handlers.
	* `World(xg, yg, sleep, disableBegin, disableEnd, disablePre, disablePost)`

Libraries
---------

Useful modules that were written by other people or just aren't required by the engine itself.

* [Testing](lib/simple-test.md) - A simple test-runner.
* [Math Patch](lib/math-patch.md) - Patches some missing functions into the default `math` library.
* [Vec2 (x,y)](lib/vec2xy.md) - Vector2 operations using only x and y numbers, not tables or userdata.

Contributors
------------

Joshua Grams <josh@qualdan.com>
Ross Grams <ross.grams@gmail.com>

Coding conventions are in the [guide for contributors](contributing.md).

Todo
----

* Automated tests.
* Start on editor.
* Finish and test box-model GUI system.
* Figure out a nice way to handle drawing layer groups at different times
   and manage optional debug layers.
* ~~Input man~~ager. - Some stuff left on this?
    * Mouse movement.
* Make a better version of Hump.timer/chrono?
* Sound object.
* Particle Emitter.
* Physics Joint object.
* Add ray cast and point check functions to the `physics` module.
* Documentation Generator.
