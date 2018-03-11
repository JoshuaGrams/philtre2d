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

* [Matrix](engine/matrix.md) - Transformations (rotate, scale,
  skew, translate) represented as 3x3 matrices (2D homogeneous
  coordinates).

* [Physics](engine/physics.md) - Holds the physics callback
  handlers and manages named collision groups.

Objects
-------

* [Body](engine/body.md) - Physics body object.
	* `Body.new(world, type, x, y, shapes, prop)`
* Sprite - Object containing an image.
	* `Sprite.new(image, ox, oy, x, y, angle, sx, sy, kx, ky)`
* [Camera](https://github.com/rgrams/lovercam/blob/master/Readme.md) - Camera object (by Lovercam)
	* `Camera.new(pos, angle, zoom_or_area, scale_mode, fixed_aspect_ratio, inactive)`
* GUI Sprite - Sprite with anchors and that scales when parent is resized.
	* `Gui_sprite.new(image, ox, oy, x, y, angle, sx, sy, ax, ay, scale_mode, kx, ky)`
* GUI Root - Root 'window' object for GUI. Needs to get `love.resize` calls.
	* `Gui_root.new()`


Todo
----

* Automated tests.

* Start on editor.

* ~~Scene-tree - prevent path overlaps!~~
* Scene-tree - set_parent()
* Input manager
* Asset loader - should only load each asset once
    * Just use Cargo? (it loads things only when they are used)
* ~~Physics wrapper~~
    * ~~one function to init world & set callbacks~~
	* ~~holds physics callback handlers~~
* Pausing
    * flag to stop update (but not draw) from continuing down the tree
    * pause/resume function call down the tree to stop sounds?
        * One recursive call rather than pause/resume functions on every single object?
    * stop input?
* Sound object
    * pre-allocate multiple voices (sources)
* Text/'Label' object
* Joint object (physics)
* ~~Add vec2 library~~
* ~~Add missing math functions~~
* Sprite batching?
* GUI 9-Patch object
* GUI Stencils (for scroll boxes)
    * `love.graphics.setStencil()`
    * Need a callback after children have drawn to reset stencil
* Emitter object...
