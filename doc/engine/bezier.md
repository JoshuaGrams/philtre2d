Cubic Bezier Curves
===================

A curve is represented by an array of four "points".  A point is
an array of values rather than a table with x/y properties.
This lets us have curves in arbitrary numbers of dimensions
(e.g. colors or 3D vectors or whatever).

* `Bezier.split(b, t)` - Split the curve at `t` and return an
  array of seven points representing two curves (the middle
  point is shared between them).  The middle point is the point
  on the curve at `t`, so you can use it for that as well.

* `Bezier.toPolyline(b, tolerance, out, t0, t1)` - Convert the
  curve to a series of line segments (array of points) which
  approximate the curve to within the given tolerance.  Points
  will be appended to the optional `out` array, and will be
  tagged with `t` values if the endpoint values `t0` and `t1`
  are given.

* `Bezier.xAlwaysIncreasing(b)` - Check whether the curve is
  always going to the right (this would make it suitable for an
  animation curve using x as the time dimension).
