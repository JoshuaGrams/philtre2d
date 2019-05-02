Layout Objects
==============

This is an attempt at making some GUI helpers for laying out boxes.

An object which wants to participate in layout must provide two methods:

* `obj:request()` returns a table `{w = number, h = number}` with the
  requested size.

* `obj:allocate(x, y, w, h)` will be called to set the actual size. The
  allocated size may be larger or smaller than the requested size, and the
  object is just supposed to deal with whatever it gets.

Basic Usage
-----------

Create your layout objects and add them to the scene tree. It's easiest if
you build them in a tree with a single Box object at the base. Then you
just need to call allocate() on the root Box with the screen width and
height, once on load, and then on love.resize.

-----

The current objects are:

* `Box(width, height)` - An invisible box that resizes to fit whatever
  allocation it is given and passes on its allocation to all of its children.

* `Fit(mode, child, space, padding)` - fits a single child object into the
  allocated box. I'm not sure I understand the code any more, but I have a
  whole bunch of tests for this, so it probably does actually work. I'll
  have to try to make the code clearer.

	* `mode` is a string: 'size'/'width'/'height'/'aspect'.
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

	* `space` is a table of up to four values, keyed to each side (left/right
	  /top/bottom). The values can be objects, which will be scaled to fill
    any extra space, or they can be `true`. If you don't specify any, or if
    you specify both left/right or top/bottom, it will center the child. If
    you specify an object for only one side on an axis, the child will be
    pushed to the opposite side.

  * `padding` is either a number (for equal padding on all sides), or a
    table. Valid keys for the table are `x` and `y` (for equal padding on
    left/right and top/bottom, respectively) and `left`, `right`, `top`,
    and `bottom`. Setting `x` will override `left` and `right`, likewise
    for `y`. If you use objects to take up extra space inside the fit box,
    they we be scaled to fit inside the padding.

* `Row(spacing, homogeneous, children)` - Lays out its child objects in a
  row. All the child objects are stretched vertically to the allocated height
  of the row.

	* `spacing` - A number giving the distance between children (but not at
	  the ends).

	* `homogeneous` - When `true`, divides up the space into equal chunks for
     each child before figuring the other allocation options. So children
     using 'none' and 'space' modes will behave the same, and children using
     'stretch' mode will only expand to fill their own equal chunk. Changing
     the anchor `dir` of children will only affect the order, not their
     spacing. In non-homogeneous rows, children get allocated enough space
     for their width, and the remaining space is divided up between children
     using the 'space' or 'stretch' modes.

	* `children` - a list of child object specifers: `{obj, dir, extra, padding}`.

		* `obj` - The child object.

		* `dir` - 'start'/'end' - Which side of the row. to anchor the child to.

		* `extra` - 'none'/'space'/'stretch' - Controls if this child gets
        extra space, and if so, what it does with it.
         * `'none'` - The child only gets enough space for its width, or a
           share proportional to its width if the whole row is too short.
         * `'space'` - The child gets a share of any leftover space
           proportional to its width and will be centered in this space.
         * `'stretch'` - The child gets the same extra space as with 'space',
           but instead of just being centered inside, it is stretched to fill
           it.

		* `padding` - Space to place on either side of the object.

* `Column(spacing, homogeneous, children)` - Same parameters as `Row`, but
  lays its children out vertically instead of horizontally.

* `Sprite` and `Quad` can also be layout objects.

