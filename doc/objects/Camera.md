Camera
======

Basic Usage
-----------

First, add a camera to your scene tree. Second, in `love.draw()`, add `Camera.current:applyTransform()` before you draw world-space objects, and `Camera.current:resetTransform()` afterward. Lastly, in `love.resize(w, h)`, call `Camera.setAllViewports(0, 0, w, h)`.

Constructor
-----------

### Camera(x, y, angle, zoom_or_area, scale_mode, fixed_aspect_ratio, inactive)

_PARAMETERS_
* __x, y__ <kbd>numbers</kbd> - _optional_ - The initial x and y pos of the camera. Default to 0, 0.
* __angle__ <kbd>number</kbd> - _optional_ - The initial rotation of the camera. Defaults to 0.
* __zoom_or_area__ <kbd>number | table | vector2</kbd> - _optional_ - Either the initial zoom or the initial view area of the camera. Pass in a number, and it will be used as a zoom value. Pass in a table or vector type (anything with `x, y`, `w, h`, or `[1], [2]` fields), and it will be used as a view area width and height, and the camera's zoom will be calculated based on this. The actual area rendered may not match this exactly, it depends on your window proportion and any fixed aspect ratio you have set. The necessary adjustments will be made based on the camera's scale mode. ("expand view" cameras will still zoom, based on a "fixed area" calculation). Defaults to 1.
* __scale_mode__ <kbd>string</kbd> - _optional_ - The camera's scale mode, which determines how it handles window resizing. Must be one of the following: (Defaults to "fixed area")
	* __"expand view"__ - How Löve works normally---zoom doesn't change---if the window is made larger a larger area is rendered, and vice versa.
	* __"fixed area"__ - Lovercam's default (because it's the best). The camera zooms in or out to show the same _area_ of game world, regardless of window size and proportion.
	* __"fixed width"__ - The camera zooms to show the same horizontal amount of world. The top and bottom will be cropped or expanded depending on the window proportion.
	* __"fixed height"__ - The camera zooms to show the same vertical amount of space. The sides will be cropped or expanded depending on the window proportion.
* __fixed_aspect_ratio__ <kbd>number</kbd> _optional_ - The aspect ratio that the viewport will be fixed to (if specified). If you pass in a value here, the camera will crop the area that it draws to as necessary maintain this aspect ratio. It will either crop the top and bottom, or left and right, depending on the aspect ratio and your window proportion. The cropping is applied and removed along with the camera's transform (with `apply_transform` and `reset_transform`). Defaults to `nil` (no aspect ratio enforced).
* __inactive__ <kbd>bool</kbd> _optional_ - If the camera should be inactive when initialized. This just means the camera won't be set as the active camera. Defaults to `false` (i.e. active).

Methods
-------

### Camera.setAllViewports(x, y, w, h)
Set the viewport of all cameras. All arguments are in pixels: they are unaffected by any transform that may be set. This may alter the zoom of your cameras, depending on their scale mode. ("expand view" mode cameras keep the same zoom.) Call this function on the Camera _module_. You _can_ also call it on a camera object, but that doesn't make a lot of sense. Note it does not take a `self` parameter.

_PARAMETERS_
* __x__ <kbd>number</kbd> - Unused. Will be for setting a custom viewport position.
* __y__ <kbd>number</kbd> - Unused. Will be for setting a custom viewport position.
* __w__ <kbd>number</kbd> - The new width of the window.
* __h__ <kbd>number</kbd> - The new height of the window.

### Camera.setViewport(self, x, y, w, h)
Updates this camera's viewport, possibly changing its zoom. All arguments are in pixels: they are unaffected by any transform that may be set.

_PARAMETERS_
* __x__ <kbd>number</kbd> - Unused. Will be for setting a custom viewport position.
* __y__ <kbd>number</kbd> - Unused. Will be for setting a custom viewport position.
* __w__ <kbd>number</kbd> - The new width of the window.
* __h__ <kbd>number</kbd> - The new height of the window.

### Camera.applyTransform(self)
Adds this camera's view transform (position, rotation, and zoom) to Löve's render transform stack.

### Camera.resetTransform(self)
Resets to the last render transform (`love.graphics.pop()`)

### Camera.activate(self)
Activates/switches to this camera.

### Camera.screenToWorld(self, x, y, is_delta)
Transforms `x` and `y` from screen coordinates to world coordinates based on this camera's position, rotation, and zoom.

_PARAMETERS_
* __x__ <kbd>number</kbd> - The screen x coordinate to transform.
* __y__ <kbd>number</kbd> - The screen y coordinate to transform.
* __is_delta__ <kbd>bool</kbd> - _optional_ - If the coordinates are for a _change_ in position (or size), rather than an absolute position. Defaults to `false`.

_RETURNS_
* __x__ <kbd>number</kbd> - The corresponding world x coordinate.
* __y__ <kbd>number</kbd> - The corresponding world y coordinate.


### Camera.worldToScreen(self, x, y, is_delta)
Transform `x` and `x` from world coordinates to screen coordinates based on this camera's position, rotation, and zoom.

_PARAMETERS_
* __x__ <kbd>number</kbd> - The world x coordinate to transform.
* __y__ <kbd>number</kbd> - The world y coordinate to transform.
* __delta__ <kbd>bool</kbd> - _optional_ - If the coordinates are for a _change_ in position (or size), rather than an absolute position. Defaults to `false`.

_RETURNS_
* __x__ <kbd>number</kbd> - The corresponding screen x coordinate.
* __y__ <kbd>number</kbd> - The corresponding screen y coordinate.

### Camera.zoomIn(self, z, xScreen, yScreen)
Zoom the camera in or out by a percentage. Sets the camera's `zoom` property to `zoom * (1 + z)`, and optionally zooms in at a position other than the camera center.

_PARAMETERS_
* __z__ <kbd>number</kbd> - The percent of the current zoom value to add or subtract.
* __xScreen__ <kbd>number</kbd> - _optional_ - The zoom should be centered on this screen x coordinate (instead of the camera center).
* __yScreen__ <kbd>number</kbd> - _optional_ - The zoom should be centered on this screen y coordinate (instead of the camera center).

### Camera.shake(self, dist, dur, falloff)
Adds a shake to the camera. The shake will last for `dur` seconds, randomly offsetting the camera's position every frame by a maximum distance of +/-`dist`, and optionally rotating it as well. The shake effect will falloff to zero over its duration. By default it uses linear falloff. For each shake you can optionally specify the fallof function, as "linear" or "quadratic", or you can change the default by setting `Camera.shake_falloff`.

Use `Camera.shake_rot_mult` to globally control how strong the rotational shake effect is (in +/= radians / `dist`). It defaults to `0.001`. Set it to zero to disable rotational shake.

_PARAMETERS_
* __dist__ <kbd>number</kbd> - The "intensity" of the shake. The length of the maximum offset it may apply.
* __dur__ <kbd>number</kbd> - How long the shake will last, in seconds.
* __falloff__ <kbd>string</kbd> - _optional_ - The falloff type for the shake to use. Can be either "linear" or "quadratic". Defaults to "linear" (or `Camera.shake_falloff`).

### Camera.perlinShake(self, dist, dur, freq, falloff)
Adds a shake to the camera that will use Perlin noise rather than normal randomness to generate the shake position (and rotation). This gives two benefits: 1) the shake will look correct if the game is run in slow-motion, and 2) you can get a slightly wider variety of effects by varying the frequency parameter. Set `Camera.shake_freq` to change the default frequency, or specify a custom value for each shake.

_PARAMETERS_
* __dist__ <kbd>number</kbd> - The "intensity" of the shake. The length of the maximum offset it may apply.
* __dur__ <kbd>number</kbd> - How long the shake will last, in seconds.
* __freq__ <kbd>number</kbd> - _optional_ - The frequency of the shake. This defaults to `8`, which will look pretty similar to a regular shake. You can set it lower to get a slower, gentler shake, like a handheld camera effect.
* __falloff__ <kbd>string</kbd> - _optional_ - The falloff type for the shake to use. Can be either "linear" or "quadratic". Defaults to "linear" (or `Camera.shake_falloff`).

### Camera.recoil(self, vec, dur, falloff)
Adds a recoil to the camera. This is sort of like a shake, only it just offsets the camera by the vector you specify--smoothly falling off to (0, 0) over `dur`. The falloff function for each recoil can optionally be set to "linear" or "quadratic" (defaults to "quadratic"), or you can change the default by setting `Camera.recoil_falloff`.

_PARAMETERS_
* __vec__ <kbd>table | vector</kbd> - The vector of the recoil. The initial offset it applies to the camera. Must have `x` and `y` fields.
* __duration__ <kbd>number</kbd> - How long the recoil will last, in seconds.
* __falloff__ <kbd>string</kbd> - _optional_ - The falloff type for the shake to use. Can be either "linear" or "quadratic". Defaults to "quadratic" (or `Camera.recoil_falloff`).

### Camera.stopShaking(self)
Cancels all shakes and recoils on this camera.

### Camera.follow(self, obj, allowMultiFollow, weight, deadzone)
Tells this camera to smoothly follow `obj`. This requires that `obj` has a property `pos` with `x` and `y` elements. Set the camera's `follow_lerp_speed` property to adjust the smoothing speed. If `allowMultiFollow` is true then `obj` will be added to a list of objects that the camera is following---the camera's lerp target will be the average position of all objects on the list. The optional `weight` parameter allows you to control how much each followed object influences the camera position. You might set it to, say, 1 for your character, and 0.5 for the mouse cursor for a top-down shooter. This only has an effect if the camera is following multiple objects. Call `cam:follow()` again with the same object to update the weight.

To set a deadzone on the camera follow (the camera won't move unless the object moves out of the deadzone), supply a table with `x`, `y`, `w`, and `h` fields. These fields should contain 0-to-1 screen percentage values that describe the deadzone rectangle. If you are using a fixed aspect ratio camera, the deadzone will be based on the viewport area, not the full window. Deadzones work _per-object_. If your camera is following a single object and you want to change which object that is without changing the deadzone, you can just put `true` for the `deadzone`, and the deadzone settings for the previous object will be copied and used for the new object. For this to work, `allowMultiFollow` must be `false` and the camera can't be following multiple objects.

_PARAMETERS_
* __obj__ <kbd>table</kbd> - The object to follow. This must be a table with a property `pos` that has `x` and `y` elements.
* __allowMultiFollow__ <kbd>bool</kbd> - _optional_ - Whether to add `obj` to the list of objects to follow, or to replace the list with only `obj`. Defaults to `false`.
* __weight__ <kbd>number</kbd> - _optional_ - The averaging weight for this object. This only matters if the camera is following multiple objects. Higher numbers will make the camera follow this object more closely than the other objects, and vice versa. The actual number doesn't matter, only its value relative to the weights of the other objects this camera is following. Defaults to 1.
* __deadzone__ <kbd>table | bool</kbd> - _optional_ - The deadzone rectangle, a table with `x`, `y`, `w`, and `h` fields. (x and y of the top left corner, and width and height.) These should be 0-to-1 screen percentages. If the window changes, the deadzone rectangle will adapt to the new window/viewport size according to these percentages. You can also put `true` for the `deadzone` to copy an existing deadzone to a new object (see the description above).

### Camera.unfollow(self, obj)
Removes `obj` from the camera's list of followed objects. If no object is given, the camera will unfollow anything and everything it is currently following.

_PARAMETERS_
* __obj__ <kbd>table</kbd> - _optional_ - The object to stop following. Leave out this argument to unfollow everything.

### Camera.setBounds(self, lt, rt, top, bot)
Sets limits on how far the edge of the camera view can travel, in world coordinates. Call this with no arguments to remove the bounds. If the bounds are smaller than the camera view in either direction then the camera's position will be locked to the center of the bounds area in that axis.

_PARAMETERS_
* __lt__ <kbd>number</kbd> - The x position of the left edge of the bounds.
* __rt__ <kbd>number</kbd> - The x position of the right edge of the bounds.
* __top__ <kbd>number</kbd> - The y position of the top edge of the bounds.
* __bot__ <kbd>number</kbd> - The y position of the bottom edge of the bounds.

Properties
----------

### Module Defaults
By default these aren't set on the camera objects, they're just inherited as meta-properties from the module. So you can either change them on the module to change the global defaults, or set them on individual cameras to just change how that camera behaves.

#### Camera.current
_DEFAULT:_ the fallback camera.

A reference to the current camera. This is either the last created camera that was not initialized as inactive, or the last camera that you called `:activate()` on. There is a fallback camera that is used if no other cameras exist.

#### Camera.shake_falloff
_DEFAULT:_ "linear"

The default falloff function for camera shakes (perlin and standard). Can be either "linear" or "quadratic"

#### Camera.recoil_falloff
_DEFAULT:_ "quadratic"

The default falloff function for camera recoils. Can be either "linear" or "quadratic"

#### Camera.shake_rot_mult
_DEFAULT:_ 0.001

The default amount of rotational shake relative to the shake `dist`. (in +/= radians / dist). It defaults to 0.001. Set it to zero to disable rotational shake.

#### Camera.shake_freq
_DEFAULT:_ 8

Default frequency for Perlin shakes.

#### Camera.follow_lerp_speed
_DEFAULT:_ 3

Default lerp speed for following.

#### Camera.pivot
_DEFAULT:_ { x = 0.5, y = 0.5 }

Positions the center of rotation and scaling as a fraction of the camera's viewport. The default of 0.5, 0.5 means the view will rotate around the center of the viewport. Setting it to 0, 0 would cause the view to rotate around and scale from the top left corner of the viewport. Changes will not take effect until you call `Camera.setViewport`.

#### Camera.viewport_align
_DEFAULT:_ { x = 0.5, y = 0.5 }

Controls where the camera puts black bars if its using a fixed aspect ratio. The default of 0.5, 0.5 means any black bars will be split evenly on either axis, centering the viewport within the window. Setting it to 0, 0 would align the viewport to the top left corner of the window--any black bars would be on the bottom or the right.

### Camera Properties
Useful properties set on camera objects, not on the class module. These are in addition to the usual Object properties of course.

#### self.scale_mode
The scale mode the camera uses to adjust its zoom when the window is resized.

#### self.aspect_ratio
The aspect ratio that the camera will lock the viewport to, if using a fixed-aspect-ratio camera. Otherwise this will be `nil`.

#### self.zoom
The zoom multiplier of the camera. Higher values mean the camera is zoomed in, lower means it is zoomed out.

#### self.vp
The viewport properties that the camera is using. This is a table with the following properties:
* __x, y__ - The x and y offset of the viewport, from the top left corner of the window. Will be 0, 0 for non-fixed-aspect-ratio cameras.
* __w, h__ - The width and height of the viewport. Will be equal to the window dimensions for non-fixed-aspect-ratio cameras.

#### self.pivot
_DEFAULT:_ `Camera.pivot` (center of viewport).

Positions the center of rotation and scaling as a fraction of the camera's viewport. If not set, `Camera.pivot` will be used instead. Changes will not take effect until you call `Camera.setViewport`.
