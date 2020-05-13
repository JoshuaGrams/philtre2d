Physics
=======

A physics utility module. Helps manage named collision categories so you don't have to remember arbitrary numbers and has helper functions for collision queries.

Basic Physics Usage
-------------------

Add a World object to your scene, and add Bodies as descendants of it.

When Bodies are init they search up the tree for the nearest World (reporting an error if they don't find one). As an Object in the scene tree, the World will get updates and pass them on to the Box2D world. The World will use `Object.call()` to send callbacks to each Body involved in a collision and any scripts it has. By default all the callbacks are enabled, you can disable them when you create the World. See the World documentation for the list of callbacks.

Module Functions
----------------

### physics.setCategoryNames(...)
Saves a table mapping string names to physics category indices (1-16). Pass in up to 16 different strings (as individual arguments).

### physics.getCategoriesBitmask(...)
Takes a list of category names and returns the bitmask matching all of them.

### physics.getMaskBitmask(...)
Takes a list of category names and returns a bitmask with all categories enabled _except_ those specified.

### physics.isInCategory(bitmask, category)
Takes a bitmask and a category name, returns true if the bitmask has that category enabled.

### physics.shouldCollide(catsA, maskA, catsB, maskB)
Takes two sets of Category and Mask bitmasks and check if they intersect--if two objects with those categories and masks should collide.

> Note: You can get the bitmasks from a fixture with
`categories, mask = Fixture:getFilterData()`.

### physics.touchingBox(lt, rt, top, bot, world)
Gets a list of any fixtures whose Axis-Aligned Bounding Box overlaps the AABB you specify. It does _not_ check against the actual shapes of fixtures, only AABB to AABB.
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

### physics.raycast(x1, y1, x2, y2, world, mode, categories, mask)
Queries a ray from (x1, y1) to (x2, y2). `mode` can be "any", "all", or "closest".

* "any" - returns true if anything was hit, otherwise nil.
* "all" - returns nil or an array of all hit results, in the following format:
* "closest" - returns nil, or the single hit result closest to the start of the ray.

Hit results are in a dictionary format:
```
{
	fixture = the hit fixture.
	x, y = the position of the contact.
	xn, yn = the normal of the hit edge.
	fraction = the fractional distance of the hit along the ray vector.
}
```

### physics.getWorld(object)
Searches up the tree starting with `object`'s parent for the nearest World ancestor. Useful for getting the right world to use for `physics.touchingBox()` and `physics.atPoint()`.

_PARAMETERS_
* __object__ <kbd>Object</kbd> - The Object in the scene-tree to start search from. (It starts by checking its parent.)

_RETURNS_
* __world__ <kbd>userdata | nil</kbd> - The nearest Love2D world object, or `nil` if none was found.
