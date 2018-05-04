Philtre 2D
==========

Engine
------

* [Scene Tree](engine/scene-tree.md) - Handles object
  collections and transforms.

* [Draw Order](engine/draw-order.md) - Cooperates with the scene
  graph to draw objects by depth or by layer, for cases where
  drawing them in order of scene graph traversal isn't
  sufficient.

* [Input](engine/input.md) - Bind physical axes and buttons to
  form game input axes and buttons.

* [Matrix](engine/matrix.md) - Transformations (rotate, scale,
  skew, translate) represented as 3x3 matrices (2D homogeneous
  coordinates).

* [Physics](engine/physics.md) - Some physics utility functions.
  For now, manages named collision groups. TODO: raycasts, point
  checks.

Objects
-------

* [Body](engine/Body.md) - Physics body object.
	* `Body(type, x, y, angle, shapes, prop, ignore_parent_transform)`
* [Camera](engine/Camera.md) - Camera object.
	* `Camera(x, y, angle, zoom_or_area, scale_mode, fixed_aspect_ratio, inactive)`
* GUI Root - Root 'window' object for GUI. Needs to get `love.resize` calls.
	* `GuiRoot.new()`
* GUI Sprite - Sprite with anchors and that scales when parent is resized.
	* `GuiSprite.new(image, ox, oy, x, y, angle, sx, sy, ax, ay, scale_mode, kx, ky)`
* GUI Text - Text object with anchors and nice scaling
	* `GuiText.new(x, y, angle, text, font_filename, font_size, wrap_limit, align, sx, sy, ax, ay, scale_mode, ox, oy, kx, ky)`
* [Object](engine/Object.md) - Base 'game object' class.
	* `Object(x, y, angle, sx, sy, kx, ky)`
* Sprite - Object containing an image.
	* `Sprite(image, x, y, angle, sx, sy, color, ox, oy, kx, ky)`
* Text - Object for rendering text.
	* `Text.new(x, y, angle, text, font, wrap_limit, align, sx, sy, ox, oy, kx, ky)`
* [World](engine/World.md) - Object with its own physics world and callback handlers.
	* `World(xg, yg, sleep, disableBegin, disableEnd, disablePre, disablePost)`

Libraries
---------

* [Testing](simple-test.md) - A simple test-runner.

Todo
----

* Automated tests.
* Start on editor.
* Better GUI system.
* ~~Input man~~ager. - Some stuff left on this?
* Make a better version of Hump.timer.
* Scene-tree - A way to change parents. (`set_parent()`)
* Sound object.
* Particle Emitter.
* Physics Joint object.
