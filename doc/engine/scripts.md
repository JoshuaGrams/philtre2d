Scripts
=======

There is a built-in "script" system for objects in the scene-tree (inheriting Object), designed to allow multiple scripts per object and reusing scripts between multiple object types. You don't have to use scripts, you can make your own object classes with inheritance or do whatever else you want.

Each script is just a table containing certain functions. When `Object:call(function_name)` is used, the named function is first called on the object itself, and then on any scripts it has, in order, if a script has that function name defined.

The first argument, `self`, refers to the object that holds the script. Scripts do not have any built-in, private space of their own to store data for their object instance, all scripts share the same `self`.

Each object's `scripts` property is either `nil`, or a list of scripts. You can modify this at any time. Generally you would set an object's scripts before you add it to the Scene-Tree.

Basic Engine Callbacks
----------------------

* __`init(self)`__ - Called after an object is added to the Scene-Tree. This callback happens bottom-up, so children will always get init before their parent.

* __`final(self)`__ - Called right before an object is removed from the Scene-Tree.

* __`update(self, dt)`__ - Called by the Scene-Tree once every frame.

* __`draw(self)`__ - Called by the Draw-Order once per frame, after update. Any Löve2D drawing operations (see [love.graphics](https://love2d.org/wiki/love.graphics)) used during this callback will happen in object local space (i.e. position (0, 0) is the object's position).

Input Callback
--------------

* __`input(self, actionName, value, change, rawChange, isRepeat, x, y, dx, dy, isTouch, presses)`__ - Called once for every input event, if the object has input enabled. See [Input](input.md).

Physics Callbacks
-----------------
> NOTE: The contact normal points away from self when `isMyContact` is true.

* __`beginContact(self, selfFixt, otherFixt, otherObj, contact, isMyContact)`__ - Called when two objects collide or begin overlapping.

* __`endContact(self, fixtA, fixtB, objA, objB, destroyedContact, isMyContact)`__ - Called when two objects stop overlapping.

> NOTE: If this is a delayed callback from the physics update the contact will be destroyed -- which means you can't call any of its methods. It's still included in case you want to use it as a table key or something.

* __`preSolve(self, selfFixt, otherFixt, otherObj, contact, isMyContact)`__ - Called just before a collision gets resolved. Can be used to disable or otherwise modify the collision response, see [Contact](https://love2d.org/wiki/Contact).

* __`postSolve(self, selfFixt, otherFixt, otherObj, contact, isMyContact, normImpulse, tanImpulse)`__ - Called just after a collision is resolved.

Example
-------

```lua
-- Create a script on the fly:
local myScript = {
	init = function(self)
		print("Hi from "..self.name.."!")
	end
}

-- Load a script from a module:
local otherScript = require "player.player_script"

local obj = Object()
obj.scripts = { myScript, otherScript }
scene:add(obj)

-- Alternate method using Philtre global function, mod():
local obj2 = mod(Object(), {scripts = { myScript, otherScript }})
scene:add(obj2)
```
