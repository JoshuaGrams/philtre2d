local T = require 'lib.simple-test'

local Layout = require 'engine.layout'

return {
	"GUI Layout Column (heterogeneous)",
	{
		function()
			local col = Layout.Column(0, false, {
				{ Layout.Box(50, 10) },
				{ Layout.Box(49, 15) }
			})
			T.has(col:request(), {w=50, h=25}, "request", "col")
		end,
		function()
			local col = Layout.Column(5, false, {
				{ Layout.Box(50, 10) },
				{ Layout.Box(50, 15), 'end' },
				{ Layout.Box(50, 10) }
			})
			T.has(col:request(), {w=50, h=45}, "request (with spacing)", "col")

		end,
		function()
			T.note("Heterogeneous column: adequate width.")
			local boxes = {
				{Layout.Box(50, 10)},
				{Layout.Box(50, 15), 'end'},
				{Layout.Box(50, 10), 'start', 'stretch'}
			}
			local spacing = 5
			local col = Layout.Column(spacing, false, boxes)
			local x, y, w, h = 10, -50, 80, 100
			col:allocate(x, y, w, h)

			T.has(boxes[1][1], {
				pos = { x = 0, y = 0 }, width = w, height = 10
			}, "first box at top, doesn't stretch", "box")
			T.has(boxes[2][1], {
				pos = { x = 0, y = h - 15 }, width = w, height = 15
			}, "second box at bottom, doesn't stretch", "box")
			T.has(boxes[3][1], {
				pos = { x = 0, y = 10 + spacing },
				width = w, height = h - 10 - 15 - 2 * spacing
			}, "third box below first, stretches", "box")
		end,
		function()
			T.note("Heterogeneous column: still fits.")
			local boxes = {
				{Layout.Box(50, 10)},
				{Layout.Box(50, 15), 'end'},
				{Layout.Box(50, 10), 'start', 'stretch'}
			}
			local spacing = 5
			local col = Layout.Column(spacing, false, boxes)
			local x, y, w, h = 10, 10, 80, 46
			col:allocate(x, y, w, h)

			T.has(boxes[1][1], {
				pos = { x = 0, y = 0 },
				width = w, height = 10
			}, "first box at top, doesn't stretch", "box")
			T.has(boxes[2][1], {
				pos = { x = 0, y = h - 15 },
				width = w, height = 15
			}, "second box at bottom, doesn't stretch", "box")
			T.has(boxes[3][1], {
				pos = { x = 0, y = 10 + spacing },
				width = w, height = 11
			}, "third box below first, stretches", "box")
		end,
		function()
			T.note("Heterogeneous column: all boxes squashed.")
			local boxes = {
				{Layout.Box(50, 10)},
				{Layout.Box(50, 15), 'end'},
				{Layout.Box(50, 10), 'start', 'stretch'}
			}
			local spacing = 5
			local col = Layout.Column(spacing, false, boxes)
			local x, y, w, h = 10, 10, 80, 38
			col:allocate(x, y, w, h)

			T.has(boxes[1][1], {
				pos = { x = 0, y = 0 }, width = w, height = 8
			}, "first box at top, squashed", "box")
			T.has(boxes[2][1], {
				pos = { x = 0, y = h - 12 }, width = w, height = 12
			}, "second box at bottom, squashed", "box")
			T.has(boxes[3][1], {
				pos = { x = 0, y = 8 + spacing },
				width = w, height = 8
			}, "third box below first, squashed", "box")
		end,
		function()
			T.note("Heterogeneous column: height less than spacing.")
			local boxes = {
				{Layout.Box(50, 10)},
				{Layout.Box(50, 15)},
				{Layout.Box(50, 10), 'start', 'stretch'}
			}
			local spacing = 5
			local col = Layout.Column(spacing, false, boxes)
			local x, y, w, h = 10, 10, 50, 8
			col:allocate(x, y, w, h)

			T.has(boxes[1][1], {
				pos = {x = 0, y = 0 },
				width = w, height = 0
			}, "first box at top, 0 width", "box")
			T.has(boxes[2][1], {
				pos = {x = 0, y = spacing },
				width = w, height = 0
			}, "second box below first, 0 width", "box")
			T.has(boxes[3][1], {
				pos = { x = 0, y = h },
				width = w, height = 0
			}, "third box at bottom, 0 width", "box")
		end,
		function()
			T.note("Heterogeneous column with padding: height less than spacing.")
			local boxes = {
				{Layout.Box(50, 10)},
				{Layout.Box(50, 15)},
				{Layout.Box(50, 10), 'start', 'stretch'}
			}
			local spacing = 5
			local col = Layout.Column(spacing, false, boxes)
			local x, y, w, h = -100, -100, 50, 8
			col:allocate(x, y, w, h)

			T.has(boxes[1][1], {
				pos = { x = 0, y = 0 }, width = w, height = 0
			}, "first box at top, 0 width", "box")
			T.has(boxes[2][1], {
				pos = { x = 0, y = spacing }, width = w, height =0
			}, "second box below first, 0 width", "box")
			T.has(boxes[3][1], {
				pos = { x = 0, y = h }, width = w, height = 0
			}, "third box at bottom, 0 width", "box")
		end
	}
}
