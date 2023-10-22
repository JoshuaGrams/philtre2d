Draw Order
==========

Draws objects by layer.  Supports layer groupings.

Create a draw order with:

* `DrawOrder(layers, [default_layer]) -> order`

`layers` is either a list of layer names (which will be placed in a single group named `all`) or a dictionary of named groups.

Within a layer, objects are drawn in the order they are added (so the ones added first will be behind the others).

`default_layer` is optional: if none is provided, it will be set to the top layer of the first group.  Objects with no layer will be drawn in their parent's layer, or in `default_layer` if no ancestor specifies a layer.

For instance:

	groups = DrawOrder({
		"gui",
		"bullets", "player", "enemies",
		"platforms", "background",
	})

or:

	groups = DrawOrder({
		gui = { "gui" },
		objects = { "bullets", "player", "enemies" },
		world = { "platforms", "background" }
	}, "enemies")


The scene tree clears the draw order and adds all the objects each frame, so there is currently no method for removing objects from a layer.

* `order:draw(groups)` - Draw the specified groups.  You can pass either a string or a list of strings (in order from top to bottom).  If you do not specify any groups, it will try to draw the group named `all` (which may not exist if you have defined your own groups).

* `order:clear([layer_name])` - Remove all objects from a specified layer, or from all layers in all groups.

* `order:addObject(object)` - An object may have a `layer` property giving a layer name.  If none is given, it will be added to the current layer.

* `order:addFunction(layer, matrix, function, ...)` - Add a draw function to the given layer.  The transform given by `matrix` will be applied before the function is called.  Any extra arguments will be passed on to the function.

* `order:saveCurrentLayer()` - push the current layer onto a stack.

* `order:restoreCurrentLayer()` - pop the top layer from the stack and set it as the current layer.


-----

You can also add or remove layers on the fly:

* `order:addLayer(name, [index]) -> layer` - Added to bottom of layer group by default.

* `order:removeLayer(name)`
