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

* __beginContact__(self, selfFixture, otherFixture, otherObject, contact)

* __endContact__(self, selfFixture, otherFixture, otherObject, contact)

* __preSolve__(self, selfFixture, otherFixture, otherObject, contact)

* __postSolve__(self, selfFixture, otherFixture, otherObject, contact, normImpulse, tanImpulse)
