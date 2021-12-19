World
=====

### World(xg, yg, sleep, disableBegin, disableEnd, disablePre, disablePost)
Creates a new object for passing updates to the physics world as part of the scene-tree. Each World object has its own physics world and its own callbacks. By default all callbacks are enabled. Access the physics world via the object's `world` property.

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

Collision Callbacks
-------------------

If enabled, these functions will get called on both objects involved in the collision and any scripts they have, if any of them have these function names defined.

> NOTE: The contact normal is relative to the edge on objA (i.e. it always points away from objA).

* __`beginContact(self, fixtA, fixtB, objA, objB, contact)`__ - Called when two objects collide or begin overlapping.

* __`endContact(self, fixtA, fixtB, objA, objB, destroyedContact)`__ - Called when two objects stop overlapping.

> NOTE: If this is a delayed callback from the physics update, the contact will be destroyed -- which means you can't call any of its methods. It's still included in case you want to use it as a table key or something.

* __`preSolve(self, fixtA, fixtB, objA, objB, contact)`__ - Called just before a collision gets resolved. Can be used to disable or otherwise modify the collision response, see [Contact](https://love2d.org/wiki/Contact).

* __`postSolve(self, fixtA, fixtB, objA, objB, contact, normImpulse, tanImpulse)`__ - Called just after a collision is resolved.
