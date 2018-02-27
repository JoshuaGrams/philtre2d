Draw Order
==========

Handles lists of objects by layer/depth.  Supports both named
layers and depths.  I recommend that you use integer depths,
though currently it should accept any number.

Create a draw order with:

* `DrawOrder.new(default_layer_name, default_depth) -> order`

Named layers must be added prior to use:

* `order:add_layer(depth, name) -> layer`

* `order:remove_layer(depth)`

Within a layer, objects are drawn in the order they are added
(so the ones added first will be behind the others).  Each
frame, you will want to clear the order, add objects, and then
draw the whole set:

* `order:clear()` - Remove all objects.

* `order:add(object)` - An object may have a `layer` property
  which is either a name string or an integer depth.  If none is
  given, it will be added to the current layer.

* `order:save_current_layer()` - push the current layer onto a
  stack.

* `order:restore_current_layer()` - pop the top layer from the
  stack and set it as the current layer.

* `order:draw()` - Draw everything.


Todo
----

* Can we set a `depth` property on an object on init or when it
  is added to the scene tree, and then on update, just use depth
  instead of named layers?  But what if we want some objects to
  have a depth relative to their parent?  So if the parent's
  depth changes, theirs needs to change too.
