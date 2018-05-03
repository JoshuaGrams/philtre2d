local T = require 'lib.simple-test'

local Layout = require 'engine.layout'

return {
	"GUI Layout",
	{
		function()
			local box = Layout.Box(10, 50)
			T.has(box:request(), {w=10, h=50}, "request", "box")
		end,
		function()
			local row = Layout.Row(0, false, {
				{ Layout.Box(10, 50) },
				{ Layout.Box(15, 49) }
			})
			T.has(row:request(), {w=25, h=50}, "request", "row")
		end,
		function()
			local row = Layout.Row(5, false, {
				{ Layout.Box(10, 50) },
				{ Layout.Box(15, 50), 'end' },
				{ Layout.Box(10, 50) }
			})
			T.has(row:request(), {w=45, h=50}, "request (with spacing)", "row")

			row.homogeneous = true
			req = row:request()
			T.is(req.w, 45, "row width request (spacing, homogeneous)")
			T.is(req.h, 50, "row height request (spacing, homogeneous)")
		end,
		function()
			T.note("Homogeneous row: adequate width.")
			local s1 = Layout.Box(10, 50)
			local e1 = Layout.Box(15, 50)
			local s2 = Layout.Box(10, 50)
			local boxes = {
				{s1},
				{e1, 'end'},
				{s2, 'start', 'stretch'}
			}
			local spacing = 5
			local row = Layout.Row(spacing, true, boxes)
			local x, y, w, h = -50, 10, 100, 80
			local aw = w - spacing * (#boxes - 1)
			local itemWidth = aw / #boxes
			row:allocate(x, y, w, h)

			local ix = x + 0.5 * (itemWidth - 10)
			T.is(s1.pos.x, ix, "first box at left")
			T.is(s1.width, 10, "first box doesn't stretch")
			T.is(s1.pos.y, y, "first box at top")
			T.is(s1.height, h, "first box should get full height")

			ix = (x + w) - itemWidth + 0.5 * (itemWidth - 15)
			T.is(e1.pos.x, ix, "second box at right")
			T.is(e1.width, 15, "second box doesn't stretch")
			T.is(e1.pos.y, y, "second box at top")
			T.is(e1.height, h, "second box should get full height")

			ix = x + itemWidth + spacing
			T.is(s2.pos.x, ix, "third box to right of first")
			T.is(s2.width, itemWidth, "third box stretches")
			T.is(s2.pos.y, y, "second box at top")
			T.is(s2.height, h, "second box should get full height")
		end,
		function()
			T.note("Homogeneous row: one box squashed.")
			local s1 = Layout.Box(10, 50)
			local e1 = Layout.Box(15, 50)
			local s2 = Layout.Box(10, 50)
			local boxes = {
				{s1},
				{e1, 'end'},
				{s2, 'start', 'stretch'}
			}
			local spacing = 5
			local row = Layout.Row(spacing, true, boxes)
			local x, y, w, h = 10, 10, 46, 80
			local aw = math.max(0, w - spacing * (#boxes - 1))
			local itemWidth = aw / #boxes
			row:allocate(x, y, w, h)

			local ix = x + 0.5 * (itemWidth - 10)
			T.is(s1.pos.x, ix, "first box at left")
			T.is(s1.width, 10, "first box doesn't stretch")
			T.is(s1.pos.y, y, "first box at top")
			T.is(s1.height, h, "first box should get full height")

			ix = (x + w) - itemWidth
			T.is(e1.pos.x, ix, "second box at right")
			T.is(e1.width, itemWidth, "second box gets squashed")
			T.is(e1.pos.y, y, "second box at top")
			T.is(e1.height, h, "second box should get full height")

			ix = x + itemWidth + spacing
			T.is(s2.pos.x, ix, "third box to right of first")
			T.is(s2.width, itemWidth, "third box stretches")
			T.is(s2.pos.y, y, "second box at top")
			T.is(s2.height, h, "second box should get full height")
		end,
		function()
			T.note("Homogeneous row: all boxes squashed.")
			local s1 = Layout.Box(10, 50)
			local e1 = Layout.Box(15, 50)
			local s2 = Layout.Box(10, 50)
			local boxes = {
				{s1},
				{e1, 'end'},
				{s2, 'start', 'stretch'}
			}
			local spacing = 5
			local row = Layout.Row(spacing, true, boxes)
			local x, y, w, h = 10, 10, 37, 80
			local aw = math.max(0, w - spacing * (#boxes - 1))
			local itemWidth = aw / #boxes
			row:allocate(x, y, w, h)

			local ix = x
			T.is(s1.pos.x, ix, "first box at left")
			T.is(s1.width, itemWidth, "first box gets 9 width")
			T.is(s1.pos.y, y, "first box at top")
			T.is(s1.height, h, "first box should get full height")

			ix = (x + w) - itemWidth
			T.is(e1.pos.x, ix, "second box at right")
			T.is(e1.width, itemWidth, "second box gets 9 width")
			T.is(e1.pos.y, y, "second box at top")
			T.is(e1.height, h, "second box should get full height")

			ix = x + itemWidth + spacing
			T.is(s2.pos.x, ix, "third box to right of first")
			T.is(s2.width, itemWidth, "third box gets 9 width")
			T.is(s2.pos.y, y, "second box at top")
			T.is(s2.height, h, "second box should get full height")
		end,
		function()
			T.note("Homogeneous row: width less than spacing.")
			local s1 = Layout.Box(10, 50)
			local s2 = Layout.Box(15, 50)
			local s3 = Layout.Box(10, 50)
			local boxes = {
				{s1},
				{s2},
				{s3, 'start', 'stretch'}
			}
			local spacing = 5
			local row = Layout.Row(spacing, true, boxes)
			local x, y, w, h = 10, 10, 8, 50
			row:allocate(x, y, w, h)

			T.is(s1.pos.x, x, "first box at left")
			T.is(s1.width, 0, "first box gets 0 width")
			T.is(s1.pos.y, y, "first box at top")
			T.is(s1.height, h, "first box should get full height")

			local ix = x + spacing
			T.is(s2.pos.x, ix, "second box to right of first")
			T.is(s2.width, 0, "second box gets 0 width")
			T.is(s2.pos.y, y, "second box at top")
			T.is(s2.height, h, "second box should get full height")

			ix = x + w
			T.is(s3.pos.x, ix, "third box at end")
			T.is(s3.width, 0, "third box gets 0 width")
			T.is(s3.pos.y, y, "second box at top")
			T.is(s3.height, h, "second box should get full height")
		end,
		function()
			T.note("Homogeneous row with padding: width less than spacing.")
			local s1 = Layout.Box(10, 50)
			local s2 = Layout.Box(15, 50)
			local s3 = Layout.Box(10, 50)
			local boxes = {
				{s1},
				{s2},
				{s3, 'start', 'stretch'}
			}
			local spacing = 5
			local row = Layout.Row(spacing, true, boxes)
			local x, y, w, h = -100, -100, 8, 50
			row:allocate(x, y, w, h)

			T.is(s1.pos.x, x, "first box at left")
			T.is(s1.width, 0, "first box gets 0 width")
			T.is(s1.pos.y, y, "first box at top")
			T.is(s1.height, h, "first box should get full height")

			local ix = x + spacing
			T.is(s2.pos.x, ix, "second box to right of first")
			T.is(s2.width, 0, "second box gets 0 width")
			T.is(s2.pos.y, y, "second box at top")
			T.is(s2.height, h, "second box should get full height")

			ix = x + w
			T.is(s3.pos.x, ix, "third box at end")
			T.is(s3.width, 0, "third box gets 0 width")
			T.is(s3.pos.y, y, "second box at top")
			T.is(s3.height, h, "second box should get full height")
		end,
		function()
			T.note("Heterogeneous row: adequate width.")
			local s1 = Layout.Box(10, 50)
			local e1 = Layout.Box(15, 50)
			local s2 = Layout.Box(10, 50)
			local boxes = {
				{s1},
				{e1, 'end'},
				{s2, 'start', 'stretch'}
			}
			local spacing = 5
			local row = Layout.Row(spacing, false, boxes)
			local x, y, w, h = -50, 10, 100, 80
			row:allocate(x, y, w, h)

			local s1A = {pos={x=x, y=y}, width=10, height=h}
			local e1A = {pos={x=x+w-15, y=y}, width=15, height=h}
			local s2A = {
				pos = {x=x+10+spacing, y=y},
				width = w - 10 - 15 - 2 * spacing,
				height = h
			}
			T.has(s1, s1A, "first box at left, doesn't stretch")
			T.has(e1, e1A, "second box at right, doesn't stretch")
			T.has(s2, s2A, "third box to right of first, stretches")
		end
	}
}
