Philtre 2D
==========

A WIP set of minimal, pure lua, game engine pieces built on top of Löve2D.

Does not restrict the use of any Löve2D features, only adds some framework for building larger games.

We have started writing some [documentation here](doc/index.md) (very WIP).

### Features:

* __Scene tree.__
	- Arbitrarily nest and attach objects.
	- Customizable object transforms (the included objects mainly use 3x3 matrices for position, rotation, scale, and skew).
	- Adjust the time scale at any level for pausing or slow-motion effects.
* __Layered draw-order system.__
	- Layers can have user-specified sorting, allowing Y-sorting for "top down" games, etc.
* __Camera.__
	- Supports position, rotation, and zoom.
	- 4 scale modes for adapting to different window sizes (or add your own).
	- Screen-to-world and world-to-screen coordinate conversion.
	- Multiple cameras.
	- Simple and Perlin/Simplex screen shake.
	- Customizable smoothed camera following (deadzone and following multiple targets supported).
	- Bounds limits.
* __Input handling.__
	- Maps key, gamepad button, mouse button, mouse wheel, or joystick inputs into unified "button" or "axis" actions.
	- Freely rebindable at runtime. Can bind multiple inputs to a single action, or vice versa.
	- Input stack to control ordering and consuming of input.
* __Simple caching module for loaded assets.__
* __Physics helper module.__
	- Handles named collision groups & masks.
	- Convenient functions for collision queries (point checks, AABB checks, & raycasts).
* __Extensible building-block classes for objects in the scene tree.__
	- Object - Base class with transformation & visibility methods.
	- Sprite & Quad - Drawable objects with images or sprite-sheet pieces.
	- World - A physics world. Dispenses collision callbacks.
	- Body - A physics body. Supports multiple fixtures, etc.
	- Camera - A camera object.
	- Text - An object for displaying text with optional wrapping & alignment.
