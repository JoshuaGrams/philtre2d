Physics
=======

Holds the physics callback handlers and manages named collision groups.

Module functions
----------------

### physics.init(xg, yg, sleep, scene_tree, disableBegin, disableEnd, disablePre, disablePost)
Creates a physics world and sets its callbacks. By default all callbacks are enabled.

_PARAMETERS_
* __xg__ <kbd>number</kbd> - X gravity.
* __yg__ <kbd>number</kbd> - Y gravity.
* __sleep__ <kbd>bool</kbd> - Whether the bodies in this world are allowed to sleep.
* __scene_tree__ <kbd>table</kbd> - The scene-tree that the physics objects will be in.
* __disableBegin__ <kbd>bool</kbd> - Pass `true` to disable beginContact callbacks.
* __disableEnd__ <kbd>bool</kbd> - Pass `true` to disable endContact callbacks.
* __disablePre__ <kbd>bool</kbd> - Pass `true` to disable preSolve callbacks.
* __disablePost__ <kbd>bool</kbd> - Pass `true` to disable postSolve callbacks.

_RETURNS_
* __world__ <kbd>World</kbd> - The new physics world.

### physics.set_scene(scene_tree)
Sets the scene-tree that the physics callbacks will use to find objects.

_PARAMETERS_
* __scene_tree__ <kbd>table</kbd> - The scene-tree object.

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
