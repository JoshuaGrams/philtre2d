Physics
=======

Constructs new physics root objects with physics worlds and callback handling, and manages global named collision groups.

Module functions
----------------

### physics.new(xg, yg, sleep, disableBegin, disableEnd, disablePre, disablePost)
Creates a new object for passing updates to the physics world as part of the scene-tree. Each object has its own physics world and sets its callbacks. By default all callbacks are enabled. Access the physics world via `obj.world`.

_PARAMETERS_
* __xg__ <kbd>number</kbd> - X gravity.
* __yg__ <kbd>number</kbd> - Y gravity.
* __sleep__ <kbd>bool</kbd> - Whether the bodies in this world are allowed to sleep.
* __disableBegin__ <kbd>bool</kbd> - Pass `true` to disable beginContact callbacks.
* __disableEnd__ <kbd>bool</kbd> - Pass `true` to disable endContact callbacks.
* __disablePre__ <kbd>bool</kbd> - Pass `true` to disable preSolve callbacks.
* __disablePost__ <kbd>bool</kbd> - Pass `true` to disable postSolve callbacks.

_RETURNS_
* __physics object__ <kbd>table</kbd> - The new physics object.

### physics.set_groups(...)
Saves a table mapping string names to physics category indices (1-16). Pass in up to 16 different strings (as individual arguments).

### physics.groups(...)
Gets a list of group indices from mapped group names. Pass in up to 16 different strings (as individual arguments).

_RETURNS_
* __groups__ <kbd>table-numbers</kbd> - A table of category indices corresponding to the group names given.

Collision Callbacks
-------------------

If enabled, these functions will get called on both objects involved in the collision and any scripts they have, if any of them have these function names defined.

* __beginContact__(self, self_fixture, other_fixture, other_object, hit)

* __endContact__(self, self_fixture, other_fixture, other_object, hit)

* __preSolve__(self, self_fixture, other_fixture, other_object, hit)

* __postSolve__(self, self_fixture, other_fixture, other_object, hit, normImpulse, tanImpulse)
