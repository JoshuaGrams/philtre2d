Matrix
======

A matrix `m` stores a 2D transformation as three vectors: the
new x-vector (`m.ux`, `m.uy`), the new y-vector (`m.vx`,
`m.vy`), and the new origin (`m.x`, `m.y`).  To transform a
vector `(x, y)`, we start at the new origin, move `x` units
along the `u` vector, then `y` units along the `v` vector.

But if you want to transform a vector that represents a
direction, you want to leave out the origin.  So we pretend that
every vector has a third value (`w`) which tells "how much" of
the origin to include (defaults to 1, that is, all of it).  You
can transform a direction vector by passing 0 for `w`.

To combine two matrix transforms, we use the first matrix to
transform all three vectors of the second.  But the `u` and `v`
vectors are directions, while the origin is a position.  So the
matrix is technically a 3x3 array (each vector has a `w` value
telling whether it is a direction or a position).  But since the
last entries are always 0, 0, and 1, we leave them out and just
pretend they are there.


Contents
--------

A table (`M`) containing the following:

* `M.identity` - the do-nothing transform.  Note that this is
  just a single table, so be careful not to modify it.

* `M.matrix(x, y, radians=0, x_scale=1, y_scale=x_scale,
  x_skew=0, y_skew=0, m={})` - Create a new transformation
  matrix.  Since the order matters, this is the equivalent of
  skewing, scaling, rotating, then translating.  All parameters
  except `x` and `y` are optional.  If you pass in an existing
  table `m`, it will set the matrix properties on that instead
  of creating a new table.

* `M.x(m, x, y, w=1)` - Use the matrix `m` to transform a
  vector.  `w` is optional and defaults to 1, but if you want to
  transform a direction vector, you can pass 0.  If you're
  familiar with the math, you may like to know that this is
  backwards: it actually treats '(x, y, w)' as a row vector and
  performs `v*m` so that transformations occur from left to
  right (the order in which you read english text).

* `M.xM(m, n, out={})` - Combine two transformations `m` and `n`,
  putting the result in `out` (if you pass a table) or a new
  table.  Note that I have chosen to represent vectors as row
  vectors (multiplying `v*m` with the vector on the left), so
  when combining two matrices, `m` will happen first and `n`
  second.

* `M.invert(m, out={})` - Compute the inverse transform (the one
  that undoes the effects of `m`, putting it it `out` or
  creating a new table.  Note that not all transformations are
  invertible (for instance, if you scale the x-axis by zero,
  there's no way to get the x information back afterwards).  If
  you pass a non-invertible matrix, this function will return
  `false`.

* `M.parameters(m) -> radians, x_scale, y_scale, x_skew, y_skew` -
  Compute the angle, scale, and skew represented by the matrix
  `m`.  Note that the matrix always contains the translation
  (origin) so you can get it directly from `m.x` and `m.y`.
