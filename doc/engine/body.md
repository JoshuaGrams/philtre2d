Body
====

Constructor
-----------

### Body.new(world, type, x, y, shapes, prop)
Construct a new Body object. The actual body, shapes, and fixtures are not created until init().

_PARAMETERS_
* __world__ <kbd>World</kbd> - The physics world
* __type__ <kbd>String(BodyType)</kbd> - The body type: 'static', 'dynamic', or 'kinematic'.
* __x, y__ <kbd>number</kbd> - The initial position of the body
* __shapes__ <kbd>table</kbd> - The shape/fixture data for the body. In the following format:
```lua
	{
		-- shape 1
		{ 'shape type', {shape_arg_1, shape_arg_2, ...}, prop=value, prop2=value2, ... },
		-- shape 2 - Example:
		{ 'circle', {50} },
		-- shape 3 - Example:
		{ 'rectangle', {25, -10, 300, 100, math.pi/4}, groups={1, 5, 6, 7}, masks={3}, density=5}
	}
```
*
	* Available shape types are: 'circle', 'rectangle', 'polygon', 'edge', or 'chain'.
	* Available properties are: 'sensor', 'groups'<kbd>list</kbd>, 'masks'<kbd>list</kbd>, 'friction', 'restitution',

* __prop__ <kbd>table</kbd> - Any non-default properties for the body.
	* Available properties are: 'angle', 'linDamp', 'angDamp', 'bullet', 'fixedRot', and 'gScale'.