local T = require 'lib.simple-test'

local Layout = require 'engine.layout'

return {
	"GUI Layout Column (homogeneous)",
	"Homogeneous column: requested size",
	function()
		local col = Layout.Column(0, false, {
			{ Layout.Box(50, 10) },
			{ Layout.Box(49, 15) }
		})
		T.has(col:request(), {w=50, h=25}, "request", "col")
	end,
	function()
		local col = Layout.Column(5, true, {
			{ Layout.Box(50, 10) },
			{ Layout.Box(50, 15), 'end' },
			{ Layout.Box(50, 10) }
		})
		T.has(col:request(), {w=50, h=45}, "request (spacing, homogeneous)", "col")
	end,
	"Homogeneous column: adequate height.",
	function()
		local boxes = {
			{Layout.Box(50, 10)},
			{Layout.Box(50, 15), 'end'},
			{Layout.Box(50, 10), 'start', 'stretch'}
		}
		local spacing = 5
		local col = Layout.Column(spacing, true, boxes)
		local x, y, w, h = 10, -50, 80, 100
		local alloc = h - spacing * (#boxes - 1)
		local itemHeight = alloc / #boxes
		col:allocate(x, y, w, h)

		T.has(boxes[1][1], {
			pos = { x = 0, y = 0.5*(itemHeight-10) },
			width = w, height = 10,
		}, "first box at top, doesn't stretch", "box")
		T.has(boxes[2][1], {
			pos = { x = 0, y = h - itemHeight + 0.5 * (itemHeight - 15) },
			width = w, height = 15
		}, "second box at bottom, doesn't stretch", "box")
		T.has(boxes[3][1], {
			pos = { x = 0, y = itemHeight + spacing },
			width = w, height = itemHeight
		}, "third box below first, stretches", "box")
	end,
	"Homogeneous column: one box squashed.",
	function()
		local boxes = {
			{Layout.Box(50, 10)},
			{Layout.Box(50, 15), 'end'},
			{Layout.Box(50, 10), 'start', 'stretch'}
		}
		local spacing = 5
		local col = Layout.Column(spacing, true, boxes)
		local x, y, w, h = 10, 10, 80, 46
		local alloc = math.max(0, h - spacing * (#boxes - 1))
		local itemHeight = alloc / #boxes
		col:allocate(x, y, w, h)

		T.has(boxes[1][1], {
			pos = { x = 0, y = 0.5 * (itemHeight - 10) },
			width = w, height = 10
		}, "first box at top, doesn't stretch", "box")
		T.has(boxes[2][1], {
			pos = { x = 0, y = h - itemHeight },
			width = w, height = itemHeight
		}, "second box at bottom, gets squashed", "box")
		T.has(boxes[3][1], {
			pos = { x = 0, y = itemHeight + spacing },
			width = w, height = itemHeight
		}, "third box below first, stretches", "box")
	end,
	"Homogeneous column: all boxes squashed.",
	function()
		local boxes = {
			{Layout.Box(50, 10)},
			{Layout.Box(50, 15), 'end'},
			{Layout.Box(50, 10), 'start', 'stretch'}
		}
		local spacing = 5
		local col = Layout.Column(spacing, true, boxes)
		local x, y, w, h = 10, 10, 80, 37
		local alloc = math.max(0, h - spacing * (#boxes - 1))
		local itemHeight = alloc / #boxes
		col:allocate(x, y, w, h)

		T.has(boxes[1][1], {
			pos = { x = 0, y = 0 },
			width = w, height = itemHeight
		}, "first box at top, squashed", "box")
		T.has(boxes[2][1], {
			pos = { x = 0, y = h - itemHeight },
			width = w, height = itemHeight
		}, "second box at bottom, squashed", "box")
		T.has(boxes[3][1], {
			pos = { x = 0, y = itemHeight + spacing },
			width = w, height = itemHeight
		}, "third box below first, squashed", "box")
	end,
	"Homogeneous column: height less than spacing.",
	function()
		local boxes = {
			{Layout.Box(50, 10)},
			{Layout.Box(50, 15)},
			{Layout.Box(50, 10), 'start', 'stretch'}
		}
		local spacing = 5
		local col = Layout.Column(spacing, true, boxes)
		local x, y, w, h = 10, 10, 50, 8
		col:allocate(x, y, w, h)

		T.has(boxes[1][1], {
			pos = {x = 0, y = 0 },
			width = w, height = 0
		}, "first box at top, 0 width", "box")
		T.has(boxes[2][1], {
			pos = {x = 0, y = spacing},
			width = w, height = 0
		}, "second box below first, 0 width", "box")
		T.has(boxes[3][1], {
			pos = { x = 0, y = h },
			width = w, height = 0
		}, "third box at bottom, 0 width", "box")
	end,
	"Homogeneous column with padding: height less than spacing.",
	function()
		local boxes = {
			{Layout.Box(50, 10)},
			{Layout.Box(50, 15)},
			{Layout.Box(50, 10), 'start', 'stretch'}
		}
		local spacing = 5
		local col = Layout.Column(spacing, true, boxes)
		local x, y, w, h = -100, -100, 50, 8
		col:allocate(x, y, w, h)

		T.has(boxes[1][1], {
			pos = { x = 0, y = 0 }, width = w, height = 0
		}, "first box at top, 0 width", "box")
		T.has(boxes[2][1], {
			pos = { x = 0, y = spacing }, width = w, height = 0
		}, "second box below first, 0 width", "box")
		T.has(boxes[3][1], {
			pos = { x = 0, y = h }, width = w, height = 0
		}, "third box at bottom, 0 width", "box")
	end
}
