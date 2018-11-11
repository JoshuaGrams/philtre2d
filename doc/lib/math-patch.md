
# Math Patch

Patches some missing functions into the default `math` library.

## Functions

### math.round(x, [interval])
Rounds a number. If `interval` is specified it will round `x` to that interval, otherwise it rounds to integers.

_PARAMETERS_
* __x__ <kbd>number</kbd> - The number to be rounded.
* __interval__ <kbd>number</kbd> - _optional_ - The interval to round `x` to. For example: 0.01 to round to the second decimal place, 1000 to round to even thousands, 2.5 to round to multiples of 2.5, etc.

_RETURNS_
* __x__ <kbd>number</kbd>

### math.sign(x)
Gets the sign of `x`. Considers zero to be positive.

_PARAMETERS_
* __x__ <kbd>number</kbd> - The number to get the sign of.

_RETURNS_
* __s__ <kbd>number</kbd> - -1 or 1.

### math.clamp(x, min, max)
Clamps a number to be between `min` and `max`.

_PARAMETERS_
* __x__ <kbd>number</kbd>
* __min__ <kbd>number</kbd>
* __max__ <kbd>number</kbd>

_RETURNS_
* __x__ <kbd>number</kbd>

### math.remap(val, min_in, max_in, [min_out], [max_out])
Remaps a number from one range to another (unclamped). If an output range is not specified then the number will be remapped to the 0-1 range between `min_in` and `max_in`.

Some examples:
```lua
math.remap(1.25, 1, 2, -100, 100) --> -50

math.remap(-10, 0, -100) --> 0.1

math.remap(20, 0, -100) --> -0.2

math.remap(0.5, -1, 1, 2, -2) --> -1.0
```

_PARAMETERS_
* __val__ <kbd>number</kbd> - The number to remap.
* __min_in__ <kbd>number</kbd> - The bottom value of the input range.
* __max_in__ <kbd>number</kbd> - The top value of the input range.
* __min_out__ <kbd>number</kbd> - _optional_ - The bottom value of the output range. Defaults to 0.
* __max_out__ <kbd>number</kbd> - _optional_ - The top value of the output range. Defaults to 1.

_RETURNS_
* __v__ <kbd>number</kbd>

### math.lerp(a, b, t)
Linearly interpolate between two numbers based on a fraction. A fraction of 0 gives you `a`, and a fraction of 1 gives you `b`.

_PARAMETERS_
* __a__ <kbd>number</kbd> - The number to lerp from.
* __b__ <kbd>number</kbd> - The number to lerp to.
* __t__ <kbd>number</kbd> - The lerp fraction (unclamped).

_RETURNS_
* __x__ <kbd>number</kbd>

### math.lerpdt(a, b, s, dt)
Lerp correctly between two numbers based on time.

_PARAMETERS_
* __a__ <kbd>number</kbd> - The number to lerp from.
* __b__ <kbd>number</kbd> - The number to lerp to.
* __s__ <kbd>number</kbd> - The speed of the lerp.
* __dt__ <kbd>number</kbd> - Delta time.

_RETURNS_
* __x__ <kbd>number</kbd>

### math.angle_between(a, b)
Gets the shortest, signed angle between two angles.

_PARAMETERS_
* __a__ <kbd>number</kbd> - The angle to measure from, in radians.
* __b__ <kbd>number</kbd> - The angle to measure to, in radians.

_RETURNS_
* __angle__ <kbd>number</kbd>

### math.rand_range(min, max)
Gets a random float value between `min` and `max`. Uses `love.math.random` instead of `math.random`, but you can change this at the top of the module.

_PARAMETERS_
* __min__ <kbd>number</kbd> - The minimum value of the random range.
* __max__ <kbd>number</kbd> - The maximum value of the random range.

_RETURNS_
* __x__ <kbd>number</kbd>

### math.rand_1_to_1()
Gets a random float value between -1 and +1. Uses `love.math.random` instead of `math.random`, but you can change this at the top of the module.

_RETURNS_
* __x__ <kbd>number</kbd>

