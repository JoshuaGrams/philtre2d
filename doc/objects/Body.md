Body
====

Bodies are game objects linked to a Box2D physics body. They can be dynamic, static, or kinematic, and have any number of fixtures with different properties.

Bodies _must_ be descendants of a World object in the scene tree. On init they will search up the tree for the closest World object and create their physics body within that World's Box2D physics world (or report an error if no World is found).

The actual Box2d 'body' is not created until `init`. After it has init, you can access the body through `self.body`.

```lua
-- For example: (in a script on a Body)
local vx, vy = self.body:getLinearVelocity()
```

__Table of Contents:__

- [Constructor](#constructor)
   - [Trigger Bodies](#trigger-bodies)
   - [Shape Types](#shape-types)
   - [Shape Properties](#shape-properties)
   - [Body Properties](#body-properties)
- [Inheriting Body](#inheriting-body)
   - [Accessing Physics Methods](#accessing-physics-methods)

_See Also: [Collision Callbacks](objects/World.md#collision-callbacks)_

Constructor
-----------

### Body(type, x, y, angle, shapes, bodyProps)
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
		{ 'rectangle', {25, -10, 300, 100, math.pi/4}, categories={1, 5, 6, 7}, mask={3}, density=5}
	}

	-- 2. A single table for a single fixture body.
	-- shapes =
	{ 'polygon', { -10, -10, 10, -10, 0, 20 }, categories=physics.getCategoriesBitmask('enemies') }
	```
	* Available shape types are: 'circle', 'rectangle', 'polygon', 'edge', and 'chain'.

	* Available shape(fixture) properties are: 'sensor', 'categories', 'mask', 'group', 'friction', 'density', and 'restitution'.
* __bodyProps__ <kbd>table</kbd> - Any non-default properties for the body.
	* Available body properties are: 'linDamp', 'angDamp', 'bullet', 'fixedRot', and 'gScale'.

### Trigger Bodies

Bodies with the type 'trigger' are a sort of custom preset. The are:

* Dynamic bodies - So they will register overlap events with all other body types.
* Sensors - All of their fixtures get set to 'sensor' mode, so they get `beginContact` and `endContact` callbacks, but pass through other objects without 'hitting' them.
* Transform like regular Objects - Though technically dynamic bodies, they behave more like kinematic bodies, or any normal child Object in the scene-tree. When their parent or any ancestor moves or rotates around, they do too (like all Bodies, they still don't change scale).

### Shape Types

The names and different parameter options you can use to define shapes.

* __'circle'__
	1. `{ radius }`
	2. `{ x, y, radius }`

* __'rectangle'__
	1. `{ width, height }` _(rectangle shapes are centered)_
	2. `{ x, y, width, height, [angle = 0] }`

* __'polygon'__
	1. `{ x1, y1, x2, y2, x3, y3, ... }` _(Can take up to 8 vertices, maximum.)_
	2. `{ sequence }` _sequence = { x1, y1, x2, y2, x3, y3, ... } - i.e. You don't have to `unpack` a vertex list._

* __'edge'__
	1. `{ x1, y1, x2, y2 }`

* __'chain'__
	1. `{ loop, x1, y1, x2, y2, ... }` _loop = If the end of the chain should loop around to the first point._
	2. `{ loop, sequence }` _sequence = { x1, y1, x2, y2, x3, y3, ... }_

### Shape Properties

The optional properties that you can specify for each shape, in the constructor.

* __'density'__ - <kbd>number</kbd> - The density of the shape (default 1).

* __'sensor'__ - <kbd>bool</kbd> - If the shape is a sensor or not.

* __'categories'__ - <kbd>number</kbd> - The bitmask for the collision categories that the shape is a member of. By default it is in category 1. You can make this with `physics.getCategoriesBitmask`.

* __'mask'__ - <kbd>number</kbd> - The bitmask for the collision categories that the shape should _not_ collide with. By default it collides with everything. You can make this with `physics.getMaskBitmask`.

* __'group'__ <kbd>number</kbd> - Another setting for how this fixture collides with others. See the [Box2D overview cheatsheet](https://love2d.org/w/images/2/29/Box2D_basic_overview.png) or the [Fixture:setFilterData Doc](https://love2d.org/wiki/Fixture:setFilterData) for info on this.

* __'friction'__ - <kbd>number</kbd> - The shape's friction, in the range 0.0-1.0.

* __'restitution'__ - <kbd>number</kbd> - The restitution or 'bounciness' of the shape.

### Body Properties

The optional properties you can specify in the constructor that affect the entire Body.

* __'linDamp'__ - <kbd>number</kbd> - The linear damping of the body, from 0 to infinity. Controls how quickly the body's linear velocity will decrease over time. It is zero by default, meaning a moving body will continue moving indefinitely.

* __'angDamp'__ - <kbd>number</kbd> - The angular damping of the body, from 0 to infinity. Controls how quickly the body's angular velocity (spin) will decrease over time. It is zero by default, meaning a spinning body will continue spinning indefinitely.

* __'bullet'__ - <kbd>bool</kbd> - If the body should use Continuous Collision Detection (CCD) for detecting collisions "between frames". Off by default.

* __'fixedRot'__ - <kbd>bool</kbd> - If the body's rotation should be fixed, or if it should rotate as normal. Defaults to `false`.

* __'gScale'__ - <kbd>number</kbd> - The gravity scale of the body—a multiplier for how much this body is affected by the world's gravity.

Inheriting Body
---------------

```lua
-- `Body` is defined globally in philtre.init.
local MyClass = Body:extend()
```

If redefining .set(), .init(), or .final() on a Body subclass, you will definitely want to call the super methods. Since a physics body can't be created until the Body is in the tree as the child of a World object, most of the initialization is in Body.init(). The actual physics body is destroyed in Body.final(), so if that method is not called, you may get an undetectable, rogue physics body bouncing around.

The Body.updateTransform function is also quite important, for updating position and rotation to or from the object and its associated physics body (depending on whether it's dynamic or kinematic). Don't overwrite them unless you know what you're doing.

```lua
function MyClass.set(self, type, x, y, angle, shapes, bodyProps)
   MyClass.super.set(self, type, x, y, angle, shapes, bodyProps)
   -- Do my set stuff.
end

function MyClass.init(self)
   MyClass.super.init(self) -- Physics body, shapes, and fixtures are created here.
   -- Do my init stuff.
end

function MyClass.final(self)
   MyClass.super.final(self) -- Physics body is destroyed here.
   -- Do my final stuff.
end
```

#### Accessing Physics Methods

The Löve2D [Body](https://love2d.org/wiki/Body) object is stored on the Philtre2d Body at `self.body`. Use this to apply forces and impulses, get velocities, get inertia and mass, get the list of fixtures, etc.
