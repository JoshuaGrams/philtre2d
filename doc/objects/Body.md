Body
====

Game Objects linked to a physics body. They can be dynamic, static, or kinematic, and have any number of fixtures with different properties.

Bodies _must_ be descendants of a World object in the scene tree. On init they will search up the tree for the closest World object and create their physics body within that World's Box2D physics world (or report an error if no World is found).

> It seems pretty inefficient to search up the tree for a World every single time a Body is initialized, but it means you never have to manage references to physics worlds at all, which is great.

The actual Box2d 'body' is not created until `init`. After it has init, you can access the body through `self.body`.

```lua
-- For example: (in a script on a Body)
local vx, vy = self.body:getLinearVelocity()
```

Constructor
-----------

### Body(type, x, y, angle, shapes, body_prop, ignore_parent_transform)
Construct a new physics Body object. The actual body, shapes, and fixtures will not be created until init().

_PARAMETERS_
* __type__ <kbd>string(BodyType)</kbd> - The body type: 'static', 'dynamic', 'kinematic', or 'trigger'.
* __x, y__ <kbd>number</kbd> - The initial position of the body.
* __angle__ <kbd>number</kbd> - The initial angle of the body.
* __shapes__ <kbd>table</kbd> - The shape & fixture data for the body. This can either be in either of the following formats:
 	```lua
	-- 1. A table of tables, for multi-fixture bodies.
	-- shapes =
	{
		-- shape 1
		{ 'shape type', {shape_arg_1, shape_arg_2, ...}, prop=value, prop2=value2, ... },

		-- shape 2 - Example:
		{ 'circle', {50} },
		-- shape 3 - Example:
		{ 'rectangle', {25, -10, 300, 100, math.pi/4}, categories={1, 5, 6, 7}, masks={3}, density=5}
	}

	-- 2. A single table for a single fixture body.
	-- shapes =
	{ 'polygon', { -10, -10, 10, -10, 0, 20 }, categories=physics.categories('enemies') }
	```
	* Available shape types are: 'circle', 'rectangle', 'polygon', 'edge', and 'chain'.

	* Available shape(fixture) properties are: 'sensor', 'categories', 'masks', 'friction', 'density', and 'restitution'.
* __body_prop__ <kbd>table</kbd> - Any non-default properties for the body.
	* Available body properties are: 'linDamp', 'angDamp', 'bullet', 'fixedRot', and 'gScale'.
* __ignore_parent_transform__ <kbd>bool</kbd> - For dynamic and static bodies only: if the body should be created at global `x`, `y`, and `angle`, rather than interpreting those as local to its parent. After creation, these body types will completely ignore their parent's transform, as usual.

Trigger Bodies
--------------

Bodies with the type 'trigger' are a sort of custom preset. The are:

* Dynamic bodies - So they will register overlap events with all other body types.
* Sensors - All of their fixtures get set to 'sensor' mode, so they get `beginContact` and `endContact` callbacks, but pass through other objects without 'hitting' them.
* Transform like regular Objects - Though technically dynamic bodies, they behave more like kinematic bodies, or any normal child Object in the scene-tree. When their parent or any ancestor moves or rotates around, they do too (like all Bodies, they still don't change scale).

Shape Types
-----------
The names and different parameter options you can use to define shapes.

* __'circle'__
	1. `{ radius }`
	2. `{ x, y, radius }`

* __'rectangle'__
	1. `{ width, height }`
	2. `{ x, y, width, height, [angle = 0] }`

* __'polygon'__
	1. `{ x1, y1, x2, y2, x3, y3, ... }` - _(Can take up to 8 vertices, maximum.)_
	2. `{ sequence }` _sequence = { x1, y1, x2, y2, x3, y3, ... } - i.e. You don't have to `unpack` a vertex list._

* __'edge'__
	1. `{ x1, y1, x2, y2 }`

* __'chain'__
	1. `{ loop, x1, y1, x2, y2, ... }` _loop = If the end of the chain should loop around to the first point._
	2. `{ loop, sequence }` _sequence = { x1, y1, x2, y2, x3, y3, ... }_

Shape Properties
----------------
The optional properties that you can specify for each shape, in the constructor.

* __'sensor'__ - <kbd>bool</kbd> - If the shape is a sensor or not.

* __'categories'__ - <kbd>sequence</kbd> - The collision categories that the shape is a member of. Must be a table of category indices—like what you get from `physics.categories` or `physics.categoriesExcept`.

* __'masks'__ - <kbd>sequence</kbd> - The collision categories that the shape should _not_ collide with. Must be a table of category indices—like what you get from `physics.categories` or `physics.categoriesExcept`.

* __'friction'__ - <kbd>number</kbd> - The shape's friction, in the range 0.0-1.0.

* __'restitution'__ - <kbd>number</kbd> - The restitution or 'bounciness' of the shape.

Body Properties
---------------
The optional properties you can specify in the constructor that affect the entire Body.

* __'linDamp'__ - <kbd>number</kbd> - The linear damping of the body, from 0 to infinity. Controls how quickly the body's linear velocity will decrease over time. It is zero by default, meaning a moving body will continue moving indefinitely.

* __'angDamp'__ - <kbd>number</kbd> - The angular damping of the body, from 0 to infinity. Controls how quickly the body's angular velocity (spin) will decrease over time. It is zero by default, meaning a spinning body will continue spinning indefinitely.

* __'bullet'__ - <kbd>bool</kbd> - If the body should use Continuous Collision Detection (CCD) for detecting collisions "between frames". Off by default.

* __'fixedRot'__ - <kbd>bool</kbd> - If the body's rotation should be fixed, or if it should rotate as normal. Defaults to `false`.

* __'gScale'__ - <kbd>number</kbd> - The gravity scale of the body—a multiplier for how much this body is affected by the world's gravity.


Methods
-------

### Body.setMasks(self, maskList)
Set the masks on every fixture on the body (which categories the body should _not_ collide with). Can't be used until after the Body has been initialized (after its `init` function has been called).

_PARAMETERS_
* __maskList__ <kbd>table</kbd> - A sequence of category indices, like you may have used to construct the Body, and what you get from `physics.categories` or `physics.categoriesExcept`.
