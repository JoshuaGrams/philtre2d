World
=====

An object representing a Box2D physics world. Having a World in the scene-tree is required for using [Bodies](Body.md), and every Body must be a descendant of a World (it is recommended that any dynamic bodies are direct children of the World).

Worlds dispense collision event callbacks to the relevant objects, and can do debug drawing of contacts.

### World(xg, yg, sleep, disableBegin, disableEnd, disablePre, disablePost)
Creates a new object for passing updates to the physics world as part of the scene-tree. Each World object has its own physics world and its own callbacks. By default all callbacks are enabled.

_PARAMETERS_
* __xg__ <kbd>number</kbd> - X gravity.
* __yg__ <kbd>number</kbd> - Y gravity.
* __sleep__ <kbd>bool</kbd> - Whether the bodies in this world are allowed to sleep.
* __disableBegin__ <kbd>bool</kbd> - Pass `true` to disable beginContact callbacks.
* __disableEnd__ <kbd>bool</kbd> - Pass `true` to disable endContact callbacks.
* __disablePre__ <kbd>bool</kbd> - Pass `true` to disable preSolve callbacks.
* __disablePost__ <kbd>bool</kbd> - Pass `true` to disable postSolve callbacks.

_RETURNS_
* __World__ <kbd>table</kbd> - The new World object.

Properties
----------

#### World.world
A reference to the [love2d/box2d physics world](https://love2d.org/wiki/World).

```lua
-- Example:
self.world:setGravity(0, 1000)
```

Collision Callbacks
-------------------

If enabled, these functions will get called on both objects involved in the collision and any scripts they have, if any of them have these function names defined.

> :warning: The callbacks happen _during_ the physics world update, so you can't modify the physics world during a callback. Use World:delay() to delay a method call until just after the world finishes updating.

> NOTE: The contact normal points away from self when `isMyContact` is true.

* __`beginContact(self, selfFixt, otherFixt, otherObj, contact, isMyContact)`__ - Called when two objects collide or begin overlapping.

* __`endContact(self, selfFixt, otherFixt, otherObj, contact, isMyContact)`__ - Called when two objects stop overlapping.

* __`preSolve(self, selfFixt, otherFixt, otherObj, contact, isMyContact)`__ - Called just before a collision gets resolved. Can be used to disable or otherwise modify the collision response, see [Contact](https://love2d.org/wiki/Contact).

* __`postSolve(self, selfFixt, otherFixt, otherObj, contact, isMyContact, normImpulse, tanImpulse)`__ - Called just after a collision is resolved.

World Methods
-------------

### World.delay(self, obj, callbackName, ...)
Delay a callback until just after the world finishes updating. Useful for modifying the physics world (spawning or destroying bodies, etc) in response to a contact event.

> NOTE: Once they are init(), all Bodies store a reference to their world object under `self.world`.

```lua
-- Example:
-- From a class inheriting Body:
function Player.beginContact(self, selfFixt, otherFixt, otherObj, contact, isMyContact)
	local nx, ny = contact:getNormal()
	if isMyContact then
		nx, ny = -nx, -ny
	end
	self.world:delay(self, "hit", nx, ny)
end

function Player.hit(self, nx, ny)
	-- Do stuff
end
```
