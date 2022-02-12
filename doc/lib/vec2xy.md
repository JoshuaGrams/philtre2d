
# Vec2

Vector2 operations using only x and y numbers, not tables or userdata.

## Functions

### vec2.new([x], [y])
Make a new table with `x` and `y` elements. This is the one outlier function, just here for the occasional convenience. All the other functions specifically use x and y, _not_ tables.

_PARAMETERS_
* __x__ <kbd>number</kbd> - _optional_ - X. Defaults to 0.
* __y__ <kbd>number</kbd> - _optional_ - Y. Defaults to `x`.

_RETURNS_
* __vector__ <kbd>table</kbd> - A table with `x` and `y` elements.

### vec2.add(ax, ay, bx, by)
Add a vector to another vector.

_PARAMETERS_
* __ax__ <kbd>number</kbd> - X value of the first vector.
* __ay__ <kbd>number</kbd> - Y value of the first vector.
* __bx__ <kbd>number</kbd> - X value of the second vector.
* __by__ <kbd>number</kbd> - Y value of the second vector.

_RETURNS_
* __x__ <kbd>number</kbd>
* __y__ <kbd>number</kbd>

### vec2.sub(ax, ay, bx, by)
Subtract a vector from another vector.

_PARAMETERS_
* __ax__ <kbd>number</kbd> - X value of the first vector.
* __ay__ <kbd>number</kbd> - Y value of the first vector.
* __bx__ <kbd>number</kbd> - X value of the second vector.
* __by__ <kbd>number</kbd> - Y value of the second vector.

_RETURNS_
* __x__ <kbd>number</kbd>
* __y__ <kbd>number</kbd>

### vec2.mul(ax, ay, bx, [by])
Multiply a vector by a scalar or another vector (element-wise).

_PARAMETERS_
* __ax__ <kbd>number</kbd> - X value of the first vector.
* __ay__ <kbd>number</kbd> - Y value of the first vector.
* __bx__ <kbd>number</kbd> - The scalar value to multiply both elements the vector by, or the X value of the second vector.
* __by__ <kbd>number | nil</kbd> - _optional_ - Y value of the second vector or `nil` if multiplying the first vector by a scalar.

_RETURNS_
* __x__ <kbd>number</kbd>
* __y__ <kbd>number</kbd>

### vec2.div(ax, ay, bx, [by])
Divide a vector by a scalar or another vector (element-wise).

_PARAMETERS_
* __ax__ <kbd>number</kbd> - X value of the first vector.
* __ay__ <kbd>number</kbd> - Y value of the first vector.
* __bx__ <kbd>number</kbd> - The scalar value to divide both elements the vector by, or the X value of the second vector.
* __by__ <kbd>number | nil</kbd> - _optional_ - Y value of the second vector or `nil` if dividing the first vector by a scalar.

_RETURNS_
* __x__ <kbd>number</kbd>
* __y__ <kbd>number</kbd>

### vec2.normalize(ax, ay)
Normalize a vector to length 1. Returns 0, 0 if both `ax` and `ay` are 0.

_PARAMETERS_
* __ax__ <kbd>number</kbd> - X.
* __ay__ <kbd>number</kbd> - Y.

_RETURNS_
* __x__ <kbd>number</kbd>
* __y__ <kbd>number</kbd>

### vec2.trim(ax, ay, len)
Trim a vector to a given maximum length.

_PARAMETERS_
* __ax__ <kbd>number</kbd> - X.
* __ay__ <kbd>number</kbd> - Y.
* __len__ <kbd>number</kbd> - The maximum length to trim the vector's length to.

_RETURNS_
* __x__ <kbd>number</kbd>
* __y__ <kbd>number</kbd>

### vec2.clamp(ax, ay, min, max)
Clamp a vector's length to be between two scalar values.

_PARAMETERS_
* __ax__ <kbd>number</kbd> - X.
* __ay__ <kbd>number</kbd> - Y.
* __min__ <kbd>number</kbd> - The minimum length to trim the vector's length to.
* __max__ <kbd>number</kbd> - The maximum length to trim the vector's length to.

_RETURNS_
* __x__ <kbd>number</kbd>
* __y__ <kbd>number</kbd>

### vec2.cross(ax, ay, bx, by)
Get the cross product of two vectors.

_PARAMETERS_
* __ax__ <kbd>number</kbd> - X value of the first vector.
* __ay__ <kbd>number</kbd> - Y value of the first vector.
* __bx__ <kbd>number</kbd> - X value of the second vector.
* __by__ <kbd>number</kbd> - Y value of the second vector.

_RETURNS_
* __cross__ <kbd>number</kbd>

### vec2.dot(ax, ay, bx, by)
Get the dot product of two vectors.

_PARAMETERS_
* __ax__ <kbd>number</kbd> - X value of the first vector.
* __ay__ <kbd>number</kbd> - Y value of the first vector.
* __bx__ <kbd>number</kbd> - X value of the second vector.
* __by__ <kbd>number</kbd> - Y value of the second vector.

_RETURNS_
* __dot__ <kbd>number</kbd>

### vec2.len(ax, ay)
Get the length of a vector.

_PARAMETERS_
* __ax__ <kbd>number</kbd> - X.
* __ay__ <kbd>number</kbd> - Y.

_RETURNS_
* __length__ <kbd>number</kbd>

### vec2.len2(ax, ay)
Get the squared length of a vector.

_PARAMETERS_
* __ax__ <kbd>number</kbd> - X.
* __ay__ <kbd>number</kbd> - Y.

_RETURNS_
* __length__ <kbd>number</kbd>

### vec2.dist(ax, ay, bx, by)
Get the distance between two vector points.

_PARAMETERS_
* __ax__ <kbd>number</kbd> - X value of the first vector.
* __ay__ <kbd>number</kbd> - Y value of the first vector.
* __bx__ <kbd>number</kbd> - X value of the second vector.
* __by__ <kbd>number</kbd> - Y value of the second vector.

_RETURNS_
* __dist__ <kbd>number</kbd>

### vec2.dist2(ax, ay, bx, by)
Get the squared distance between two vector points.

_PARAMETERS_
* __ax__ <kbd>number</kbd> - X value of the first vector.
* __ay__ <kbd>number</kbd> - Y value of the first vector.
* __bx__ <kbd>number</kbd> - X value of the second vector.
* __by__ <kbd>number</kbd> - Y value of the second vector.

_RETURNS_
* __dist2__ <kbd>number</kbd>

### vec2.rotate(ax, ay, phi)
Rotate a vector by a given angle.

_PARAMETERS_
* __ax__ <kbd>number</kbd> - X.
* __ay__ <kbd>number</kbd> - Y.
* __phi__ <kbd>number</kbd> - The angle, in radians, to rotate the vector by.

_RETURNS_
* __x__ <kbd>number</kbd>
* __y__ <kbd>number</kbd>

### vec2.perpendicular(ax, ay)
Get the perpendicular vector of a vector.

_PARAMETERS_
* __ax__ <kbd>number</kbd> - X.
* __ay__ <kbd>number</kbd> - Y.

_RETURNS_
* __x__ <kbd>number</kbd>
* __y__ <kbd>number</kbd>

### vec2.angle_between(ax, ay, bx, by)
Get the smallest, signed angle from one vector to another.

_PARAMETERS_
* __ax__ <kbd>number</kbd> - X value of the first vector.
* __ay__ <kbd>number</kbd> - Y value of the first vector.
* __bx__ <kbd>number</kbd> - X value of the second vector.
* __by__ <kbd>number</kbd> - Y value of the second vector.

_RETURNS_
* __angle__ <kbd>number</kbd> - The angle between the vectors, in radians.

### vec2.lerp(ax, ay, bx, by, s)
Lerp between two vectors.

_PARAMETERS_
* __ax__ <kbd>number</kbd> - X value of the vector to lerp _from_.
* __ay__ <kbd>number</kbd> - Y value of the vector to lerp _from_.
* __bx__ <kbd>number</kbd> - X value of the vector to lerp _to_.
* __by__ <kbd>number</kbd> - Y value of the vector to lerp _to_.
* __s__ <kbd>number</kbd> - The lerp fraction (not clamped).

_RETURNS_
* __x__ <kbd>number</kbd>
* __y__ <kbd>number</kbd>

### vec2.lerpdt(ax, ay, bx, by, rate, dt)
Lerp between two vectors correctly based on time.

_PARAMETERS_
* __ax__ <kbd>number</kbd> - X value of the vector to lerp _from_.
* __ay__ <kbd>number</kbd> - Y value of the vector to lerp _from_.
* __bx__ <kbd>number</kbd> - X value of the vector to lerp _to_.
* __by__ <kbd>number</kbd> - Y value of the vector to lerp _to_.
* __rate__ <kbd>number</kbd> - The lerp fraction per second. Lerping to 0 with a rate of 0.25 will reduce the value by 25% every second.
* __dt__ <kbd>number</kbd> - Delta time.

_RETURNS_
* __x__ <kbd>number</kbd>
* __y__ <kbd>number</kbd>

### vec2.to_string(ax, ay)
Get a string representing a vector, with the pattern: `'(%+0.3f,%+0.3f)'`.

_PARAMETERS_
* __ax__ <kbd>number</kbd> - X.
* __ay__ <kbd>number</kbd> - Y.

_RETURNS_
* __string__ <kbd>string</kbd>

## Metamethods

### __call()
Links to `vec2.new(x, y)`.

_PARAMETERS_
* __x__ <kbd>number</kbd> - X.
* __y__ <kbd>number</kbd> - Y.
