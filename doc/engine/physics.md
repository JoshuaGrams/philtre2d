Physics
=======

A physics utility module. Helps manage named collision categories so you don't have to remember arbitrary numbers and has helper functions for collision queries.

Basic Physics Usage
-------------------

Add a World object to your scene, and add Bodies as descendants of it.

When Bodies are init they search up the tree for the nearest World (reporting an error if they don't find one). As an Object in the scene tree, the World will get updates and pass them on to the Box2D world. The World will use `Object.call()` to send callbacks to each Body involved in a collision and any scripts it has. By default all the callbacks are enabled, you can disable them when you create the World. See the World documentation for the list of callbacks.

Module Functions
----------------

### physics.setCategories(...)
Saves a table mapping string names to physics category indices (1-16). Pass in up to 16 different strings (as individual arguments).

### physics.categories(...)
Gets a list of category indices from mapped category names. Pass in up to 16 different strings (as individual arguments).

_RETURNS_
* __categories__ <kbd>table</kbd> - A table of category indices corresponding to the category names given. You can give this directly to the `Body` constructor for a shape's 'categories' or 'masks' property, or the `Body.setMask` method.

### physics.categoriesExcept(...)
Gets the opposite of `physics.categories`: a list of all category indices _except_ the ones corresponding to the category names given. Pass in up to 16 different strings (as individual arguments).

_RETURNS_
* __categories__ <kbd>table</kbd> - A table of category indices corresponding to all the category names _not_ given. You can give this directly to the `Body` constructor for a shape's 'categories' or 'masks' property, or the `Body.setMask` method.

### physics.categoryIndex(category_name)
Gets the corresponding index of a named category. Can be useful for checking collision results.

_PARAMETERS_
* __category_name__ <kbd>string</kbd> - The physics category name to get the matching index of.

_RETURNS_
* __index__ <kbd>number</kbd> - The category index.

### physics.getWorld(obj)
Traverses up the scene-tree to find the nearest physics world. Useful for getting the right world to use for `physics.touchingBox()` and `physics.atPoint()`.

_PARAMETERS_
* __obj__ <kbd>Object</kbd> - The Object in the scene-tree to start search from. (It starts by checking its parent.)

_RETURNS_
* __world__ <kbd>userdata | nil</kbd> - The nearest Love2D world object, or `nil` if none was found.

### physics.touchingBox(lt, rt, top, bot, world)
Gets a list of any fixtures whose Axis-Aligned Bounding Box overlaps the AABBs you specify. It does _not_ check against the actual shapes of fixtures, only AABB to AABB.
> Note: You can get the actual Object that a fixture belongs to with `fixture:getUserData()`.

_PARAMETERS_
* __lt, rt, top, bot__ <kbd>numbers</kbd> - The left-x, right-x, top-y, and bottom-y coordinates of the AABB to check, in world coordinates.
* __world__ <kbd>userdata</kbd> - The Love2D physics world to use.

_RETURNS_
* __results__ <kbd>table | nil</kbd> - A list table of all the overlapping fixtures, or `nil` if there are none.

### physics.atPoint(x, y, world)
Gets a list of any fixtures overlapping a single point. This is an accurate check against the shapes of the fixtures.
> Note: You can get the actual Object that a fixture belongs to with `fixture:getUserData()`.

_PARAMETERS_
* __x, y__ <kbd>numbers</kbd> - The x and y coordinates of the point to check, in world coordinates.
* __world__ <kbd>userdata</kbd> - The Love2D physics world to use.

_RETURNS_
* __results__ <kbd>table | nil</kbd> - A list table of all the overlapping fixtures, or `nil` if there are none.
