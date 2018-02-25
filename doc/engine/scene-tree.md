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


Todo
----

* `add_child`/`remove_child` - `add_child` needs to do the stuff
  that `init` currently does.

* Object paths.  I currently have a stupid-simple implementation
  that uses either `object.name` or the index as its local path.
  So...this should work, but you have to be careful not to use
  `table.remove` or you'll re-number the remaning children.
  Which isn't a problem immediately, but could cause a new child
  to be given the same path as an existing one.

* Remove pure collections (those with children but no transform)
  on init.  They will only be accessible through their path.
