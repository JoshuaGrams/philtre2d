local base = (...):gsub('[^%.]+.[^%.]+$', '')
local T = require(base .. 'lib.simple-test')

local Layout = require(base .. 'objects.layout.all')

return {
	"GUI Layout Row (homogeneous)",
	"Requested size",
	function()
		local row = Layout.Row(0, false, {
			{ Layout.Box(10, 50) },
			{ Layout.Box(15, 49) }
		})
		T.has(row:request(), {w=25, h=50}, "request", "row")
	end,
	function()
		local row = Layout.Row(5, true, {
			{ Layout.Box(10, 50) },
			{ Layout.Box(15, 50), 'end' },
			{ Layout.Box(10, 50) }
		})
		T.has(row:request(), {w=45, h=50}, "request (spacing, homogeneous)", "row")
	end,
	"Homogeneous row: adequate width.",
	function()
		local boxes = {
			{Layout.Box(10, 50)},
			{Layout.Box(15, 50), 'end'},
			{Layout.Box(10, 50), 'start', 'stretch'}
		}
		local spacing = 5
		local row = Layout.Row(spacing, true, boxes)
		local x, y, w, h = -50, 10, 100, 80
		local aw = w - spacing * (#boxes - 1)
		local itemWidth = aw / #boxes
		row:allocate(x, y, w, h)

		T.has(boxes[1][1], {
			pos = { x = 0.5*(itemWidth-10), y = 0 },
			width = 10, height = h
		}, "first box at left, doesn't stretch", "box")
		T.has(boxes[2][1], {
			pos = { x = w - itemWidth + 0.5 * (itemWidth - 15), y = 0 },
			width = 15, height = h
		}, "second box at right, doesn't stretch", "box")
		T.has(boxes[3][1], {
			pos = { x = itemWidth + spacing, y = 0 },
			width = itemWidth, height = h
		}, "third box to right of first, stretches", "box")
	end,
	"Homogeneous row: one box squashed.",
	function()
		local boxes = {
			{Layout.Box(10, 50)},
			{Layout.Box(15, 50), 'end'},
			{Layout.Box(10, 50), 'start', 'stretch'}
		}
		local spacing = 5
		local row = Layout.Row(spacing, true, boxes)
		local x, y, w, h = 10, 10, 46, 80
		local alloc = math.max(0, w - spacing * (#boxes - 1))
		local itemWidth = alloc / #boxes
		row:allocate(x, y, w, h)

		T.has(boxes[1][1], {
			pos = { x = 0.5 * (itemWidth - 10), y = 0 },
			width = 10, height = h
		}, "first box at left, doesn't stretch", "box")
		T.has(boxes[2][1], {
			pos = { x = w - itemWidth, y = 0 },
			width = itemWidth, height = h
		}, "second box at right, gets squashed", "box")
		T.has(boxes[3][1], {
			pos = { x = itemWidth + spacing, y = 0 },
			width = itemWidth, height = h
		}, "third box to right of first, stretches", "box")
	end,
	"Homogeneous row: all boxes squashed.",
	function()
		local boxes = {
			{Layout.Box(10, 50)},
			{Layout.Box(15, 50), 'end'},
			{Layout.Box(10, 50), 'start', 'stretch'}
		}
		local spacing = 5
		local row = Layout.Row(spacing, true, boxes)
		local x, y, w, h = 10, 10, 37, 80
		local aw = math.max(0, w - spacing * (#boxes - 1))
		local itemWidth = aw / #boxes
		row:allocate(x, y, w, h)

		T.has(boxes[1][1], {
			pos = { x = 0, y = 0 },
			width = itemWidth, height = h
		}, "first box at left, 9 width", "box")
		T.has(boxes[2][1], {
			pos = { x = w - itemWidth, y = 0 },
			width = itemWidth, height = h
		}, "second box at right, gets 9 width", "box")
		T.has(boxes[3][1], {
			pos = { x = itemWidth + spacing, y = 0 },
			width = itemWidth, height = h
		}, "third box to right of first, gets 9 width", "box")
	end,
	"Homogeneous row: width less than spacing.",
	function()
		local boxes = {
			{Layout.Box(10, 50)},
			{Layout.Box(15, 50)},
			{Layout.Box(10, 50), 'start', 'stretch'}
		}
		local spacing = 5
		local row = Layout.Row(spacing, true, boxes)
		local x, y, w, h = 10, 10, 8, 50
		row:allocate(x, y, w, h)

		T.has(boxes[1][1], {
			pos = {x = 0, y = 0 },
			width = 0, height = h
		}, "first box at left, 0 width", "box")
		T.has(boxes[2][1], {
			pos = {x = spacing, y = 0 },
			width = 0, height = h
		}, "second box to right of first, 0 width", "box")
		T.has(boxes[3][1], {
			pos = { x = w, y = 0 },
			width = 0, height = h
		}, "third box at end, 0 width", "box")
	end,
	"Homogeneous row with padding: width less than spacing.",
	function()
		local boxes = {
			{Layout.Box(10, 50)},
			{Layout.Box(15, 50)},
			{Layout.Box(10, 50), 'start', 'stretch'}
		}
		local spacing = 5
		local row = Layout.Row(spacing, true, boxes)
		local x, y, w, h = -100, -100, 8, 50
		row:allocate(x, y, w, h)

		T.has(boxes[1][1], {
			pos = { x = 0, y = 0 }, width = 0, height = h
		}, "first box at left, 0 width", "box")
		T.has(boxes[2][1], {
			pos = { x = spacing, y = 0 }, width = 0, height = h
		}, "second box to right of first, 0 width", "box")
		T.has(boxes[3][1], {
			pos = { x = w, y = 0 }, width = 0, height = h
		}, "third box at end, 0 width", "box")
	end
}
