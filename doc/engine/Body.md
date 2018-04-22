Body
====

Constructor
-----------

### Body(world, type, x, y, angle, shapes, body_prop, ignore_parent_transform)
Construct a new physics Body object. The actual body, shapes, and fixtures will not be created until init().

_PARAMETERS_
* __world__ <kbd>World</kbd> - The physics world.
* __type__ <kbd>string(BodyType)</kbd> - The body type: 'static', 'dynamic', or 'kinematic'.
* __x, y__ <kbd>number</kbd> - The initial position of the body.
* __angle__ <kbd>number</kbd> - The initial angle of the body.
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
	* Available shape types are: 'circle', 'rectangle', 'polygon', 'edge', and 'chain'.
	* Available shape(fixture) properties are: 'sensor', 'groups', 'masks', 'friction', and 'restitution'.

* __body_prop__ <kbd>table</kbd> - Any non-default properties for the body.
	* Available body properties are: 'linDamp', 'angDamp', 'bullet', 'fixedRot', and 'gScale'.
* __ignore_parent_transform__ <kbd>bool</kbd> - For dynamic and static bodies only: if the body should be created at global `x`, `y`, and `angle`, rather than interpreting those as local to its parent. After creation, these body types will completely ignore their parent's transform, as usual.