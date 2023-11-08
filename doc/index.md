Philtre 2D
==========

__Table of Contents:__

- [Prerequisites](#prerequisites)
- [Downloading with Git](#downloading-with-git)
	- [Updating](#updating)
- [Downloading Manually](#downloading-manually)
- [Minimal Usage Example](#minimal-usage-example)
- [Intended Usage Overview](#intended-usage-overview)
- [Engine](#engine)
- [Objects](#objects)
- [Libraries](#libraries)

Prerequisites
-------------

Download and install [Löve2D](https://love2d.org/). See also: [Löve2D Getting Started](https://love2d.org/wiki/Getting_Started). It is assumed that you have a basic understanding of Lua and Löve2D, these docs won't cover them.

Downloading with Git
--------------------
_(Assumes Git is installed and you are using Git Bash or another capable terminal emulator.)_

In your desired project folder, create a git repository:

	git init

Add to your git project as a submodule:

	git submodule add https://github.com/JoshuaGrams/philtre2d.git philtre

Or, with SSH:

	git submodule add git@github.com:JoshuaGrams/philtre2d.git philtre

This will produce a .gitmodules file (if you didn't already have one) and a `philtre` directory (whose SHA-1 hash won't be a hash of the directory, but will point to Philtre's HEAD).  Commit these two entries to your project repository.

### Updating

Fetch upstream engine changes with:

	git submodule update --remote --merge

This will update `philtre` to point to the new upstream HEAD, and you'll need to commit that change to your project. Alternatively, you can open the philtre folder and pull changes there like a normal git repository, and then go back up and commit the changed `philtre` file to your project.

Downloading Manually
--------------------

Go to the [main page](https://github.com/JoshuaGrams/philtre2d) of this repository, click the "Code" dropdown button and click "Download Zip". Extract the zip file into your game directory and rename the extracted folder to "philtre".

Minimal Usage Example
---------------------

```lua
-- "Hello World Example"
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
Intended Usage Overview
-----------------------

The scene tree is the core of Philtre, almost everything else depends on that. Your main.lua will handle setup and the high-level "game loop", and you will make your game features by extending the basic [object classes](#objects) (or using [scripts](engine/scripts.md)) and adding them to the scene tree.

One good setup is to have three objects at the root of your scene tree: a root object for your GUI, a game manager, and then a Physics World object to contain your level:

	SceneTree
	  ├─ GUI
	  │    └─ Menu
	  ├─ Game Manager
	  └─ Physics World / Level
	        ├─ Player
	        ├─ Camera
	        └─ Other game entities...


You would define separate GUI and game-world layer groups, so the game world can be drawn inside the camera view and the GUI drawn in screen-space on top.

The "game manager" would handle adding, removing, pausing, and un-pausing the [World](objects/World.md)/level object (since the world can't un-pause itself, and it's simpler to remove _one_ object rather than all of its children). Likewise, the GUI root object would add and remove menu objects (as children or as root-level objects).

The Player object would enable [input](engine/input.md) on itself and handle gameplay controls. It might inherit [Body](objects/Body.md) to have collision.

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

> TODO: Doc about the base-class module. Inheritance in general.

* [Body](objects/Body.md) - Physics body object.
	* **Body(** **_type_**, x, y, angle, **_shapes_**, bodyProps **)**
* [Camera](objects/Camera.md) - Camera object.
	* **Camera(** x, y, angle, zoomOrArea, scaleMode, fixedAspectRatio, inactive **)**
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
	* **Text(** **_text_**, **_font_**, x, y, angle, wrapLimit, align, sx, sy, kx, ky **)**
	* `font` can be a table `{filename, size}` or an existing font object.
	* `align` is a string: one of `left`, `center`, `right`, or `justify`.
* [World](objects/World.md) - Object with its own physics world and callback handlers.
	* **World(** xg, yg, sleep, disableBegin, disableEnd, disablePre, disablePost **)**

* [GUI Objects](objects/Gui.md) - GUI layout objects.

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
* Particle Emitter.
* Rewrite GUI system (again).
