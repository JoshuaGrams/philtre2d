local T = require 'lib.simple-test'

local Layout = require 'engine.layout'

return {
	"GUI Layout Row (heterogeneous)",
	{
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

		end,
		function()
			T.note("Heterogeneous row: adequate width.")
			local boxes = {
				{Layout.Box(10, 50)},
				{Layout.Box(15, 50), 'end'},
				{Layout.Box(10, 50), 'start', 'stretch'}
			}
			local spacing = 5
			local row = Layout.Row(spacing, false, boxes)
			local x, y, w, h = -50, 10, 100, 80
			row:allocate(x, y, w, h)

			T.has(boxes[1][1], {
				pos = { x = 0, y = 0 }, width = 10, height = h
			}, "first box at left, doesn't stretch", "box")
			T.has(boxes[2][1], {
				pos = { x = w - 15, y = 0 }, width = 15, height = h
			}, "second box at right, doesn't stretch", "box")
			T.has(boxes[3][1], {
				pos = { x = 10 + spacing, y = 0 },
				width = w - 10 - 15 - 2 * spacing, height = h
			}, "third box to right of first, stretches", "box")
		end,
		function()
			T.note("Heterogeneous row: still fits.")
			local boxes = {
				{Layout.Box(10, 50)},
				{Layout.Box(15, 50), 'end'},
				{Layout.Box(10, 50), 'start', 'stretch'}
			}
			local spacing = 5
			local row = Layout.Row(spacing, false, boxes)
			local x, y, w, h = 10, 10, 46, 80
			row:allocate(x, y, w, h)

			T.has(boxes[1][1], {
				pos = { x = 0, y = 0 },
				width = 10, height = h
			}, "first box at left, doesn't stretch", "box")
			T.has(boxes[2][1], {
				pos = { x = w - 15, y = 0 },
				width = itemWidth, height = h
			}, "second box at right, doesn't stretch", "box")
			T.has(boxes[3][1], {
				pos = { x = 10 + spacing, y = 0 },
				width = 11, height = h
			}, "third box to right of first, stretches", "box")
		end,
		function()
			T.note("Heterogeneous row: all boxes squashed.")
			local boxes = {
				{Layout.Box(10, 50)},
				{Layout.Box(15, 50), 'end'},
				{Layout.Box(10, 50), 'start', 'stretch'}
			}
			local spacing = 5
			local row = Layout.Row(spacing, false, boxes)
			local x, y, w, h = 10, 10, 38, 80
			row:allocate(x, y, w, h)

			T.has(boxes[1][1], {
				pos = { x = 0, y = 0 }, width = 8, height = h
			}, "first box at left, squashed", "box")
			T.has(boxes[2][1], {
				pos = { x = w - 12, y = 0 }, width = 12, height = h
			}, "second box at right, squashed", "box")
			T.has(boxes[3][1], {
				pos = { x = 8 + spacing, y = 0 },
				width = 8, height = h
			}, "third box to right of first, squashed", "box")
		end,
		function()
			T.note("Heterogeneous row: width less than spacing.")
			local boxes = {
				{Layout.Box(10, 50)},
				{Layout.Box(15, 50)},
				{Layout.Box(10, 50), 'start', 'stretch'}
			}
			local spacing = 5
			local row = Layout.Row(spacing, false, boxes)
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
		function()
			T.note("Heterogeneous row with padding: width less than spacing.")
			local boxes = {
				{Layout.Box(10, 50)},
				{Layout.Box(15, 50)},
				{Layout.Box(10, 50), 'start', 'stretch'}
			}
			local spacing = 5
			local row = Layout.Row(spacing, false, boxes)
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
}
