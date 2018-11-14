Layout Objects
==============

This is an attempt at making some GUI helpers for laying out boxes.

An object which wants to participate in layout must provide two methods:

* `obj:request()` returns a table `{w = number, h = number}` with the
  requested size.

* `obj:allocate(x, y, w, h)` will be called to set the actual size. The
  allocated size may be larger or smaller than the requested size, and the
  object is just supposed to deal with whatever it gets.

These objects go in the scene tree. You have to manually call `allocate` on the top-level layout object and then it will allocate its children.

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
		* `size` - Does not resize the child, just places it in the space. If
        	  the child is bigger than the available space, it is scaled down to
        	  fit, with no regard for aspect ratio.
		* `width` - Scales the child so its width fill the available  space.
		  The child's height is scaled to maintain its aspect ratio, unless
		  there is not enough room, in which case the height is scaled down to
		  fit inside the parent.
		* `height` - Likewise, scales the child's height to fit the  space.
		  Width scales to maintain aspect ratio or is scaled down to fit
		  inside the parent.
		* `aspect` - Scales the child uniformly up or down to always maintain
		  its aspect ratio while filling as much of the available space as
		  possible. There will always be some extra space unless the parent's
		  aspect ratio is the same as the child's.

	* `space` is a table of up to four objects, keyed to each side (left/right
	  /top/bottom), which will be scaled to fill any extra space. If you
	  don't specify any, or if you specify both left/right or top/bottom, it
	  will center the child. If you specify an object for only one side on
	  an axis, the child will be pushed to the opposite side.

* `Row(spacing, homogeneous, children)` - Lays out its child objects in a
  row.

	* `spacing` is a number giving the distance between children (but not at
	  the ends)

	* `homogenous` - Give each element the same amount of space? If not,
	  they get different amounts of space based on their individual widths.

	* `children` - a list of child object specifers: `{obj, dir, extra, padding}`.

		* `obj` - The child object.

		* `dir` - 'start'/'end' - Which side to put extra space on?

		* `extra` - 'none'/'space'/'stretch' - Does this element want extra
		  space, and should we center the object in the space or report it to
		  the object.

		* `padding` - Space to place on either side of the object.

* `Column(spacing, homogeneous, children)` - Same parameters as `Row`, but
  lays its children out vertically instead of horizontally.

* `Sprite` and `Quad` can also be layout objects.

