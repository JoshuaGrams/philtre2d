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

Objects
-------

* [Body](engine/body.md) - Physics body object.
	* `Body.new(world, type, x, y, shapes, prop)`
* Sprite - Object containing an image.
	* `Sprite.new(image, ox, oy, x, y, angle, sx, sy, kx, ky)`
* [Camera](https://github.com/rgrams/lovercam/blob/master/Readme.md) - Camera object (by Lovercam)
	* `Camera.new(pos, angle, zoom_or_area, scale_mode, fixed_aspect_ratio, inactive)`
* Text - Object for rendering text.
	* `Text.new(x, y, angle, text, font, wrap_limit, align, sx, sy, ox, oy, kx, ky)`
* GUI Sprite - Sprite with anchors and that scales when parent is resized.
	* `Gui_sprite.new(image, ox, oy, x, y, angle, sx, sy, ax, ay, scale_mode, kx, ky)`
* GUI Root - Root 'window' object for GUI. Needs to get `love.resize` calls.
	* `Gui_root.new()`
* GUI Text - Text object with anchors and nice scaling
	* `Gui_text.new(x, y, angle, text, font_filename, font_size, wrap_limit, align, sx, sy, ax, ay, scale_mode, ox, oy, kx, ky)`
* [Physics](engine/physics.md) - Pauseable physics root object with its own world and callback handling.
	* `physics.new(xg, yg, sleep, disableBegin, disableEnd, disablePre, disablePost)`

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
