Scene Tree
==========

Right now I'm just using nested sequences to represent a scene
tree.  These tables have no special metatable and thus no object
methods.

Each object in a tree may have the following optional
properties:

* `layer` - Name string or integer depth (distance into the
  screen).  See [Draw Order](draw-order.md) for details.

* `children` - Another sequence containing child objects.

* `p` - Table `{x=number, y=number}` giving the object's
  position (in coordinates relative to its parent).

* `angle`, `sx`, `sy`, `kx`, `ky` - rotation, scale, skew.

The scene tree functions add a few more:

* `parent` - the object's parent within the scene tree.

* `_to_world` - the local-to-world transformation.

* `_to_local` - the world-to-local transformation.  This costs a
  certain amount to compute, so it is set to `nil` unless you
  use it (by calling `T.to_local()`).


Contents
--------

A table (`T`) containing the following:

* `mod(object, properties) -> object` - copy key/value pairs
  from `properties` onto `object`, overriding any that may
  already exist.  This is a convenience function to help build
  scene trees by making it easy to add or modify any properties
  that the scene tree may need while constructing the tables.

* `to_world(obj, x, y, w) -> x2, y2` - Transform a local vector
  into world coordinates.

* `to_local(obj, x, y, w) -> x2, y2` - Transform a world vector
  into local coordinates.

* `new(draw_order, root_objects) -> tree` - Create a new scene
  tree object.  The parameters should possibly be switched
  since `draw_order` is optional, but it's much more visible
  when it comes *before* the huge scene tree data table.


A scene tree object has the following methods:

* `add(object, parent=nil)` - Add an object to the tree.  If no
  parent is given, add it at the root level.

* `remove(object)` - Remove an object from the tree.

* `get(path) -> object or nil` - Look up an object by its path.

* `update(dt)` - Traverse the tree, updating all objects with
  the given time delta.

* `draw()` - Draw all objects in the tree by calling `draw` on
  the `draw_order` (if present) or by traversing the tree (which
  draws in strict tree order and doesn't support layers).

-----

* `init(tree) -> objects_by_path` - Initialize a scene graph.
  Currently this sets the `parent`, `path`, `_to_world`, and
  `_to_local` properties on each object.  It returns a table
  indexing all objects by their paths.

* `update(tree, dt, draw_order)` - update all objects.  If
  `draw_order` is given, adds all objects with a `draw` method
  (note that you are responsible for clearing the draw order
  between updates for yourself...).

* `draw(tree)` - Draw all objects, in tree order.

* `add_child(child, parent, paths)` - Add and initialize a new
  child object (and all of its children, if any).

* `remove_child(object, paths)` - Remove `object` from its
  parent and from the path dictionary.


Todo
----

* Do we want to do something fancier with object paths?  Right
  now I'm just storing the string (where the object name is its
  `name` property or its index within its parent).  I don't
  know if there's a good way to hash paths in Lua that would be
  any faster than just storing the string.  So this should be
  good enough for now.

* Remove pure collections (those with children but no transform)
  on init.  They will only be accessible through their path.
