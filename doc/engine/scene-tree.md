Scene Tree
==========

A scene tree tracks objects and collections and manages
transforms and local coordinates for child objects.

Each object in a tree may have the following optional
properties:

* `layer` - Name string or integer depth (distance into the
  screen).  See [Draw Order](draw-order.md) for details.

* `children` - a sequence of child objects.

* `pos` - Table `{x=number, y=number}` giving the object's
  position (in coordinates relative to its parent).

* `angle`, `sx`, `sy`, `kx`, `ky` - rotation, scale, skew.

The scene tree functions add a few more:

* `parent` - the object's parent within the scene tree.  This is
  actually the nearest ancestor with a transform.  Collections
  with no transform are removed from the tree and can only be
  accessed by their path.

* `_to_world` - the local-to-world transformation.

* `_to_local` - the world-to-local transformation.  This costs a
  certain amount to compute, so it is set to `nil` unless you
  use it (by calling `T.to_local()`).


Contents
--------

A table (`T`) containing the following:

* `new(draw_order, root_objects) -> tree` - Create a new scene
  tree object.  Sets `parent`, `path`, `_to_world`, and
  `_to_local` properties on each object.

* `mod(object, properties) -> object` - copy key/value pairs
  from `properties` onto `object`, overriding any that may
  already exist.  This is a convenience function to help build
  scene trees by making it easy to add or modify any properties
  that the scene tree may need while constructing the tables.

* `object(x, y, angle, xScale, yScale, xSkew, ySkew) -> table` -
  create a table with all the transform parameters, providing
  sensible defaults for any arguments which are not given.  This
  function doesn't set a metatable, so you can do whatever you
  like with the result.

* `to_world(obj, x, y, w) -> x2, y2` - Transform a local vector
  into world coordinates.

* `to_local(obj, x, y, w) -> x2, y2` - Transform a world vector
  into local coordinates.

-----

A scene tree object has the following methods:

* `add(object, parent=nil)` - Add an object to the tree.  If no
  parent is given, add it at the root level.

* `remove(object)` - Remove an object from the tree.

* `get(path) -> object or nil` - Look up an object by its path.

* `pause(object)` - Pauses the object and its children down the tree.

* `unpause(object)` - Un-pauses the object and its children down the tree.

* `update(dt)` - Traverse the tree, updating all objects with
  the given time delta.

* `draw()` - Draw all objects in the tree by calling out to the
  `draw_order` if present, or by traversing the tree (which
  draws in strict tree order and doesn't support layers).

-----

* `update(tree, dt, draw_order)` - update all objects.  If
  `draw_order` is given, adds all objects with a `draw` method
  (note that you are responsible for clearing the draw order
  between updates for yourself...).

* `draw(tree)` - Draw all objects, in tree order.


Todo
----

* Manipulating pure collections.  If you want to move it, should
  we add a transform and re-parent all its children?  What if it
  has a layer and you change that?  Or what if you disable or
  hide it?  Hmm.  Maybe game objects need to be objects as well.
  But then we need inheritance, because we'll want them to be
  other types of object?  Or can we use composition for that?  I
  don't want to think about that yet.  Bah.  Maybe it's fine
  that pure collections are just an edit-time thing.  My main
  objections to Defold were that game objects couldn't have
  children and that you couldn't ask about the children of a
  collection, and I have already fixed both of those things.

* Automated tests

Otherwise I think this is ok for now.  We probably need to use
it a bunch and find out where the holes and weak points are.
And I imagine it's slow, but I'll worry about that later, once
everything else mostly works.
