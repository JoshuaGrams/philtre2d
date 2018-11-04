Draw Order
==========

Draws objects by layer.  Supports layer groupings.

Create a draw order with:

* `DrawOrder(layer_groups, [default_layer]) -> order`

`layer_groups` is a dictionary of named groups.  Each group is a
list of layer names in order from top to bottom.

Within a layer, objects are drawn in the order they are added
(so the ones added first will be behind the others).

`default_layer` is optional: if none is provided, it will be set
to the top layer of the first group.  Objects with no layer will
be drawn in their parent's layer, or in `default_layer` if no
ancestor specifies a layer.

For instance:

	groups = DrawOrder({
		game = {
			"bullets", "player", "enemies",
			"platforms", "background"
		},
		gui = { "gui" }
		
	}, "enemies")


The scene tree clears the draw order and adds all the objects
each frame, so there is currently no method for removing objects
from a layer.

* `order:clear()` - Remove all objects.

* `order:addObject(object)` - An object may have a `layer`
  property giving a layer name.  If none is given, it will be
  added to the current layer.  _Note that this used to be
  called_ `add`.

* `order:addFunction(layer, matrix, function, ...)` - Add a draw
  function to the given layer.  The transform given by `matrix`
  will be applied before the function is called.  Any extra
  arguments will be passed on to the function.

* `order:saveCurrentLayer()` - push the current layer onto a
  stack.

* `order:restoreCurrentLayer()` - pop the top layer from the
  stack and set it as the current layer.

* `order:draw(groups)` - Draw the specified groups.  You can
  pass either a string or a list of strings (in order from top
  to bottom).


-----

You can also add or remove layers on the fly:

* `order:addLayer(name, position, other) -> layer` - valid
  positions are `"top"`, `"bottom"`, `"above"`, and `"below"`.
  Above and below require `other` to be the name of an existing
  layer.

* `order:removeLayer(name)`
