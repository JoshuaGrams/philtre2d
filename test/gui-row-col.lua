local base = (...):gsub('[^%.]+%.[^%.]+$', '')
local T = require(base .. 'lib.simple-test')

local SceneTree = require(base .. 'objects.SceneTree')
matrix = require(base .. 'core.matrix')
local gui = require(base .. 'objects.gui.all')
local Node = gui.Node
local Row, Col = gui.Row, gui.Column

return {
	setup = function() return SceneTree() end,
	"GUI Column",
	function(scene) -- Homogeneous Column
		local col = scene:add(Col(0, true, nil, 100, 100))
		local ch1 = scene:add(Node(10, 10, nil, nil, "none", "fill"), col)
		local ch2 = scene:add(Node(10, 50, nil, nil, "none", "fill"), col)
		T.has(ch1, {h=50}, "Homogeneous height alloc to small child is correct.")
		T.has(ch2, {h=50}, "Homogeneous height alloc to large child is correct.")
		local ch3 = scene:add(Node(10, 30, nil, nil, "none", "fill"), col)
		T.has(ch1, {h=100/3}, "Homogeneous height alloc to small child after adding new child is correct.")
		T.has(ch2, {h=100/3}, "Homogeneous height alloc to large child after adding new child is correct.")
		T.has(ch3, {h=100/3}, "Homogeneous height alloc to medium child after adding new child is correct.")
		scene:remove(ch1)
		scene:remove(ch3)
		col:allocateChildren()
		T.has(ch2, {h=100}, "Homogeneous alloc to child after removing other children is correct.")
	end,
	function(scene) -- Heterogeneous Column - offsets
		local dir = -1
		local col = scene:add(Col(0, false, dir, 100, 100))
		local h1, h2 = 10, 40
		local ch1 = scene:add(Node(10, h1, nil, nil, "none", "fill"), col)
		local ch2 = scene:add(Node(10, h2, nil, nil, "none", "fill"), col)
		-- Y offset is from the parent center to the child alloc center.
		T.has(ch1.lastAlloc, {y=(50-h1/2)*dir}, "Heterogeneous Y offset alloc to child 1 is correct.")
		T.has(ch2.lastAlloc, {y=(50-h1-h2/2)*dir}, "Heterogeneous Y offset alloc to child 2 is correct.")
	end,
	function(scene) -- Heterogeneous Column - offsets - reverse dir
		local dir = 1
		local col = scene:add(Col(0, false, dir, 100, 100))
		local h1, h2 = 32, 10
		local ch1 = scene:add(Node(10, h1, nil, nil, "none", "fill"), col)
		local ch2 = scene:add(Node(10, h2, nil, nil, "none", "fill"), col)
		-- Y offset is from the parent center to the child alloc center.
		T.has(ch1.lastAlloc, {y=(50-h1/2)*dir}, "Heterogeneous reverse-dir Y offset alloc to child 1 is correct.")
		T.has(ch2.lastAlloc, {y=(50-h1-h2/2)*dir}, "Heterogeneous reverse-dir Y offset alloc to child 2 is correct.")
	end,
	function(scene) -- Heterogeneous Column
		local col = scene:add(Col(0, false, nil, 100, 100))
		local ch1 = scene:add(Node(10, 10, nil, nil, "none", "fill"), col)
		local ch2 = scene:add(Node(10, 50, nil, nil, "none", "fill"), col)
		T.has(ch1, {h=10}, "Heterogeneous alloc to small child is correct.")
		T.has(ch2, {h=50}, "Heterogeneous alloc to medium child is correct.")
		-- Add another child that makes the child height sum to 200.
		local c3height = 200 - 10 - 50 -- 140
		local ch3 = scene:add(Node(10, c3height, nil, nil, "none", "fill"), col)
		T.has(ch1, {h=10/200*100}, "Squashed heterogeneous alloc to small child after adding new child is correct.")
		T.has(ch2, {h=50/200*100}, "Squashed heterogeneous alloc to medium child after adding new child is correct.")
		T.has(ch3, {h=140/200*100}, "Squashed heterogeneous alloc to oversize child after adding new child is correct.")
		scene:remove(ch1)
		scene:remove(ch3)
		col:allocateChildren()
		T.has(ch2, {h=50}, "Heterogeneous alloc to child after removing other children is correct.")
	end,
	function(scene) -- Column with greedy child
		local col = scene:add(Col(0, false, nil, 100, 100))
		local ch1 = scene:add(Node(10, 20, nil, nil, "none", "fill"), col)
		local ch2 = scene:add(Node(10, 5, nil, nil, "none", "fill"), col)
		local ch3 = scene:add(Node(10, 30, nil, nil, "none", "fill"), col)
		ch2.isGreedy = true
		col:allocateChildren() -- Needed after setting isGreedy.
		T.has(ch2, {h=50}, "Greedy child gets allocated all extra height.")
	end,
	"GUI Row",
	function(scene) -- Homogeneous Row
		local row = scene:add(Row(0, true, nil, 100, 100))
		local ch1 = scene:add(Node(10, 10, nil, nil, "fill", "none"), row)
		local ch2 = scene:add(Node(50, 10, nil, nil, "fill", "none"), row)
		T.has(ch1, {w=50}, "Homogeneous alloc to small child is correct.")
		T.has(ch2, {w=50}, "Homogeneous alloc to large child is correct.")
		local ch3 = scene:add(Node(30, 10, nil, nil, "fill", "none"), row)
		T.has(ch1, {w=100/3}, "Homogeneous alloc to small child after adding new child is correct.")
		T.has(ch2, {w=100/3}, "Homogeneous alloc to large child after adding new child is correct.")
		T.has(ch3, {w=100/3}, "Homogeneous alloc to medium child after adding new child is correct.")
		scene:remove(ch1)
		scene:remove(ch3)
		row:allocateChildren()
		T.has(ch2, {w=100}, "Homogeneous alloc to child after removing other children is correct.")
	end,
	function(scene) -- Heterogeneous Row - offsets
		local dir = -1
		local col = scene:add(Row(0, false, dir, 100, 100))
		local w1, w2 = 10, 40
		local ch1 = scene:add(Node(w1, 10, nil, nil, "none", "fill"), col)
		local ch2 = scene:add(Node(w2, 10, nil, nil, "none", "fill"), col)
		-- X offset is from the parent center to the child alloc center.
		T.has(ch1.lastAlloc, {x=(50-w1/2)*dir}, "Heterogeneous X offset alloc to child 1 is correct.")
		T.has(ch2.lastAlloc, {x=(50-w1-w2/2)*dir}, "Heterogeneous X offset alloc to child 2 is correct.")
	end,
	function(scene) -- Heterogeneous Row - offsets - reverse dir
		local dir = 1
		local col = scene:add(Row(0, false, dir, 100, 100))
		local w1, w2 = 32, 10
		local ch1 = scene:add(Node(w1, 10, nil, nil, "none", "fill"), col)
		local ch2 = scene:add(Node(w2, 10, nil, nil, "none", "fill"), col)
		-- X offset is from the parent center to the child alloc center.
		T.has(ch1.lastAlloc, {x=(50-w1/2)*dir}, "Heterogeneous reverse-dir X offset alloc to child 1 is correct.")
		T.has(ch2.lastAlloc, {x=(50-w1-w2/2)*dir}, "Heterogeneous reverse-dir X offset alloc to child 2 is correct.")
	end,
	function(scene) -- Heterogeneous Row
		local row = scene:add(Row(0, false, nil, 100, 100))
		local ch1 = scene:add(Node(10, 10, nil, nil, "fill", "none"), row)
		local ch2 = scene:add(Node(50, 10, nil, nil, "fill", "none"), row)
		T.has(ch1, {w=10}, "Heterogeneous alloc to small child is correct.")
		T.has(ch2, {w=50}, "Heterogeneous alloc to medium child is correct.")
		-- Add another child that makes the child height sum to 200.
		local c3width = 200 - 10 - 50 -- 140
		local ch3 = scene:add(Node(c3width, 10, nil, nil, "fill", "none"), row)
		T.has(ch1, {w=10/200*100}, "Squashed heterogeneous alloc to small child after adding new child is correct.")
		T.has(ch2, {w=50/200*100}, "Squashed heterogeneous alloc to medium child after adding new child is correct.")
		T.has(ch3, {w=140/200*100}, "Squashed heterogeneous alloc to oversize child after adding new child is correct.")
		scene:remove(ch1)
		scene:remove(ch3)
		row:allocateChildren()
		T.has(ch2, {w=50}, "Heterogeneous alloc to child after removing other children is correct.")
	end,
	function(scene) -- Row with greedy child
		local row = scene:add(Row(0, false, nil, 100, 100))
		local ch1 = scene:add(Node(20, 10, nil, nil, "fill", "none"), row)
		local ch2 = scene:add(Node(5, 10, nil, nil, "fill", "none"), row)
		local ch3 = scene:add(Node(30, 10, nil, nil, "fill", "none"), row)
		ch2.isGreedy = true
		row:allocateChildren() -- Needed after setting isGreedy.
		T.has(ch2, {w=50}, "Greedy child gets allocated all extra width.")
	end,
}
