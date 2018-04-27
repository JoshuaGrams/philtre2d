local T = require 'lib.simple-test'

local Layout = require 'engine.layout'

return {
	"GUI Layout",
	{
		function()
			local box = Layout.Box.new(10, 50)
			local req = box:request()
			T.is(req.w, 10, "box width request")
			T.is(req.h, 50, "box height request")
		end,
		function()
			local row = Layout.Row.new(0, false, {
				{ Layout.Box.new(10, 50) },
				{ Layout.Box.new(15, 49) }
			})
			local req = row:request()
			T.is(req.w, 25, "row width request")
			T.is(req.h, 50, "row height request")
		end,
		function()
			local row = Layout.Row.new(5, false, {
				{ Layout.Box.new(10, 50) },
				{ Layout.Box.new(15, 50), 'end' },
				{ Layout.Box.new(10, 50) }
			})
			local req = row:request()
			T.is(req.w, 45, "row width request (spacing)")
			T.is(req.h, 50, "row height request (spacing)")

			row.homogeneous = true
			req = row:request()
			T.is(req.w, 45, "row width request (spacing, homogeneous)")
			T.is(req.h, 50, "row height request (spacing, homogeneous)")
		end,
		function()
			T.note("Homogeneous row: adequate width.")
			local s1 = Layout.Box.new(10, 50)
			local e1 = Layout.Box.new(15, 50)
			local s2 = Layout.Box.new(10, 50)
			local boxes = {
				{s1},
				{e1, 'end'},
				{s2, 'start', 'stretch'}
			}
			local spacing = 5
			local row = Layout.Row.new(spacing, true, boxes)
			local x, y, w, h = -50, 10, 100, 80
			local aw = w - spacing * (#boxes - 1)
			local itemWidth = aw / #boxes
			row:allocate(x, y, w, h)

			local ix = x + 0.5 * (itemWidth - 10)
			T.is(s1.x, ix, "first box at left")
			T.is(s1.w, 10, "first box doesn't stretch")
			T.is(s1.y, y, "first box at top")
			T.is(s1.h, h, "first box should get full height")

			ix = (x + w) - itemWidth + 0.5 * (itemWidth - 15)
			T.is(e1.x, ix, "second box at right")
			T.is(e1.w, 15, "second box doesn't stretch")
			T.is(e1.y, y, "second box at top")
			T.is(e1.h, h, "second box should get full height")

			ix = x + itemWidth + spacing
			T.is(s2.x, ix, "third box to right of first")
			T.is(s2.w, itemWidth, "third box stretches")
			T.is(s2.y, y, "second box at top")
			T.is(s2.h, h, "second box should get full height")
		end,
		function()
			T.note("Homogeneous row: one box squashed.")
			local s1 = Layout.Box.new(10, 50)
			local e1 = Layout.Box.new(15, 50)
			local s2 = Layout.Box.new(10, 50)
			local boxes = {
				{s1},
				{e1, 'end'},
				{s2, 'start', 'stretch'}
			}
			local spacing = 5
			local row = Layout.Row.new(spacing, true, boxes)
			local x, y, w, h = 10, 10, 46, 80
			local aw = math.max(0, w - spacing * (#boxes - 1))
			local itemWidth = aw / #boxes
			row:allocate(x, y, w, h)

			local ix = x + 0.5 * (itemWidth - 10)
			T.is(s1.x, ix, "first box at left")
			T.is(s1.w, 10, "first box doesn't stretch")
			T.is(s1.y, y, "first box at top")
			T.is(s1.h, h, "first box should get full height")

			ix = (x + w) - itemWidth
			T.is(e1.x, ix, "second box at right")
			T.is(e1.w, itemWidth, "second box gets squashed")
			T.is(e1.y, y, "second box at top")
			T.is(e1.h, h, "second box should get full height")

			ix = x + itemWidth + spacing
			T.is(s2.x, ix, "third box to right of first")
			T.is(s2.w, itemWidth, "third box stretches")
			T.is(s2.y, y, "second box at top")
			T.is(s2.h, h, "second box should get full height")
		end,
		function()
			T.note("Homogeneous row: all boxes squashed.")
			local s1 = Layout.Box.new(10, 50)
			local e1 = Layout.Box.new(15, 50)
			local s2 = Layout.Box.new(10, 50)
			local boxes = {
				{s1},
				{e1, 'end'},
				{s2, 'start', 'stretch'}
			}
			local spacing = 5
			local row = Layout.Row.new(spacing, true, boxes)
			local x, y, w, h = 10, 10, 37, 80
			local aw = math.max(0, w - spacing * (#boxes - 1))
			local itemWidth = aw / #boxes
			row:allocate(x, y, w, h)

			local ix = x
			T.is(s1.x, ix, "first box at left")
			T.is(s1.w, itemWidth, "first box gets 9 width")
			T.is(s1.y, y, "first box at top")
			T.is(s1.h, h, "first box should get full height")

			ix = (x + w) - itemWidth
			T.is(e1.x, ix, "second box at right")
			T.is(e1.w, itemWidth, "second box gets 9 width")
			T.is(e1.y, y, "second box at top")
			T.is(e1.h, h, "second box should get full height")

			ix = x + itemWidth + spacing
			T.is(s2.x, ix, "third box to right of first")
			T.is(s2.w, itemWidth, "third box gets 9 width")
			T.is(s2.y, y, "second box at top")
			T.is(s2.h, h, "second box should get full height")
		end,
		function()
			T.note("Homogeneous row: width less than spacing.")
			local s1 = Layout.Box.new(10, 50)
			local s2 = Layout.Box.new(15, 50)
			local s3 = Layout.Box.new(10, 50)
			local boxes = {
				{s1},
				{s2},
				{s3, 'start', 'stretch'}
			}
			local spacing = 5
			local row = Layout.Row.new(spacing, true, boxes)
			local x, y, w, h = 10, 10, 8, 50
			row:allocate(x, y, w, h)

			T.is(s1.x, x, "first box at left")
			T.is(s1.w, 0, "first box gets 0 width")
			T.is(s1.y, y, "first box at top")
			T.is(s1.h, h, "first box should get full height")

			local ix = x + spacing
			T.is(s2.x, ix, "second box to right of first")
			T.is(s2.w, 0, "second box gets 0 width")
			T.is(s2.y, y, "second box at top")
			T.is(s2.h, h, "second box should get full height")

			ix = x + w
			T.is(s3.x, ix, "third box at end")
			T.is(s3.w, 0, "third box gets 0 width")
			T.is(s3.y, y, "second box at top")
			T.is(s3.h, h, "second box should get full height")
		end,
		function()
			T.note("Homogeneous row with padding: width less than spacing.")
			local s1 = Layout.Box.new(10, 50)
			local s2 = Layout.Box.new(15, 50)
			local s3 = Layout.Box.new(10, 50)
			local boxes = {
				{s1},
				{s2},
				{s3, 'start', 'stretch'}
			}
			local spacing = 5
			local row = Layout.Row.new(spacing, true, boxes)
			local x, y, w, h = -100, -100, 8, 50
			row:allocate(x, y, w, h)

			T.is(s1.x, x, "first box at left")
			T.is(s1.w, 0, "first box gets 0 width")
			T.is(s1.y, y, "first box at top")
			T.is(s1.h, h, "first box should get full height")

			local ix = x + spacing
			T.is(s2.x, ix, "second box to right of first")
			T.is(s2.w, 0, "second box gets 0 width")
			T.is(s2.y, y, "second box at top")
			T.is(s2.h, h, "second box should get full height")

			ix = x + w
			T.is(s3.x, ix, "third box at end")
			T.is(s3.w, 0, "third box gets 0 width")
			T.is(s3.y, y, "second box at top")
			T.is(s3.h, h, "second box should get full height")
		end,
		function()
			T.note("Heterogeneous row: adequate width.")
			local s1 = Layout.Box.new(10, 50)
			local e1 = Layout.Box.new(15, 50)
			local s2 = Layout.Box.new(10, 50)
			local boxes = {
				{s1},
				{e1, 'end'},
				{s2, 'start', 'stretch'}
			}
			local spacing = 5
			local row = Layout.Row.new(spacing, false, boxes)
			local x, y, w, h = -50, 10, 100, 80
			row:allocate(x, y, w, h)

			T.is(s1.x, x, "first box at left")
			T.is(s1.w, 10, "first box doesn't stretch")
			T.is(s1.y, y, "first box at top")
			T.is(s1.h, h, "first box should get full height")

			T.is(e1.x, x + w - 15, "second box at right")
			T.is(e1.w, 15, "second box doesn't stretch")
			T.is(e1.y, y, "second box at top")
			T.is(e1.h, h, "second box should get full height")

			local ix = x + 10 + spacing
			local iw = w - 10 - 15 - 2 * spacing
			T.is(s2.x, ix, "third box to right of first")
			T.is(s2.w, iw, "third box stretches")
			T.is(s2.y, y, "second box at top")
			T.is(s2.h, h, "second box should get full height")
		end
	}
}
