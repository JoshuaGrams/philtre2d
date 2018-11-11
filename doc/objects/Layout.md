Layout Objects
==============

This is an attempt at making some GUI helpers for laying out boxes.

An object which wants to participate in layout must provide two methods:

* `obj:request()` returns a table `{w = number, h = number}` with the
  requested size.

* `obj:allocate(x, y, w, h)` will be called to set the actual size. The
  allocated size may be larger or smaller than the requested size, and the
  object is just supposed to deal with whatever it gets.

-----

The current objects are:

* `Box(width, height)` - A dummy object for testing purposes? Or for
  inheriting from?

* `Fit(mode, child, space)` - fits a single child object into the allocated
  box. I'm not sure I understand the code any more, but I have a whole bunch
  of tests for this, so it probably does actually work. I'll have to try to
  make the code clearer.

	* `mode` is a string: size/width/height/aspect. `Size` does not resize
	  the child, just places it in the space. So if the child is bigger than
	  the allocated space, this will probably break things. The others fit
	  the child width/height/aspect, placing space around it as necessary.

	* `space` is a table saying where to put the extra space. It has four
	  optional flags (left/right/top/bottom). If you don't specify any, or
	  if you specify both left/right or top/bottom, it will center the
	  child.

* `Row(spacing, homogeneous, children)` - Lays out its child objects in a
  row.

	* `spacing` is a number giving the distance between children (but not at
	  the ends)

	* `homogenous` - Give each element the same amount of space? If not,
	  they get different amounts of space based on their individual widths.

	* `children` - a list of child object specifers: `{obj={},
	  extra="none/space/stretch", padding=#}`.

		* `extra` - Does this element want extra space, and should we center
		  the object in the space or report it to the object.

		* `padding` - Space to place on either side of the object.

* `Column(spacing, homogeneous, children)` - Same parameters as `Row`, but
  lays its children out vertically instead of horizontally.

