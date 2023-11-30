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
		local col = scene:add(Col(0, true, nil, 100, "px", 100, "px"))
		local ch1 = scene:add(Node(10, "px", 100, "%"):desire(nil, 10), col)
		local ch2 = scene:add(Node(10, "px", 100, "%"):desire(nil, 50), col)
		T.has(ch1, {h=50}, "Homogeneous height alloc to small child is correct.")
		T.has(ch2, {h=50}, "Homogeneous height alloc to large child is correct.")
		local ch3 = scene:add(Node(10, "px", 100, "%"):desire(nil, 30), col)
		T.has(ch1, {h=100/3}, "Homogeneous height alloc to small child after adding new child is correct.")
		T.has(ch2, {h=100/3}, "Homogeneous height alloc to large child after adding new child is correct.")
		T.has(ch3, {h=100/3}, "Homogeneous height alloc to medium child after adding new child is correct.")
		local nonDesirous = scene:add(Node(50, "%", 50, "%"), col)
		col:allocateChildren()
		local h = 100/3
		T.ok(ch1.h == h and ch2.h == h and ch3.h == h, "Adding a non-desirous child does not take space from children in Column.")
		T.is(nonDesirous.lastAlloc.h, 100, "Non-desirous child is allocated full Column node height.")
		scene:remove(ch1)
		scene:remove(ch3)
		col:allocateChildren()
		T.has(ch2, {h=100}, "Homogeneous alloc to child after removing other children is correct.")
	end,
	function(scene) -- Heterogeneous Column - offsets
		local col = scene:add(Col(0, false, false, 100, "px", 100, "px"))
		local h1, h2 = 10, 40
		local ch1 = scene:add(Node(10, "px", 100, "%"):desire(nil, h1), col)
		local ch2 = scene:add(Node(10, "px", 100, "%"):desire(nil, h2), col)
		T.has(ch1.lastAlloc, {y=0}, "Heterogeneous Y offset alloc to child 1 is correct.")
		T.has(ch2.lastAlloc, {y=10}, "Heterogeneous Y offset alloc to child 2 is correct.")
	end,
	function(scene) -- Heterogeneous Column - offsets - reverse dir
		local col = scene:add(Col(0, false, true, 100, "px", 100, "px"))
		local h1, h2 = 32, 10
		local ch1 = scene:add(Node(10, "px", 100, "%"):desire(nil, h1), col)
		local ch2 = scene:add(Node(10, "px", 100, "%"):desire(nil, h2), col)
		T.has(ch1.lastAlloc, {y=100-32}, "Heterogeneous reverse-dir Y offset alloc to child 1 is correct.")
		T.has(ch2.lastAlloc, {y=100-32-10}, "Heterogeneous reverse-dir Y offset alloc to child 2 is correct.")
	end,
	function(scene) -- Heterogeneous Column
		local col = scene:add(Col(0, false, nil, 100, "px", 100, "px"))
		local ch1 = scene:add(Node(10, "px", 100, "%"):desire(nil, 10), col)
		local ch2 = scene:add(Node(10, "px", 100, "%"):desire(nil, 50), col)
		T.has(ch1, {h=10}, "Heterogeneous alloc to small child is correct.")
		T.has(ch2, {h=50}, "Heterogeneous alloc to medium child is correct.")
		-- Add another child that makes the child height sum to 200.
		local c3height = 200 - 10 - 50 -- 140
		local ch3 = scene:add(Node(10, "px", 100, "%"):desire(nil, c3height), col)
		T.has(ch1, {h=10/200*100}, "Squashed heterogeneous alloc to small child after adding new child is correct.")
		T.has(ch2, {h=50/200*100}, "Squashed heterogeneous alloc to medium child after adding new child is correct.")
		T.has(ch3, {h=140/200*100}, "Squashed heterogeneous alloc to oversize child after adding new child is correct.")
		scene:remove(ch1)
		scene:remove(ch3)
		col:allocateChildren()
		T.has(ch2, {h=50}, "Heterogeneous alloc to child after removing other children is correct.")
	end,
	function(scene) -- Column with greedy child
		local col = scene:add(Col(0, false, nil, 100, "px", 100, "px"))
		local ch1 = scene:add(Node(10, "px", 100, "%"):desire(nil, 20), col)
		local ch2 = scene:add(Node(10, "px", 100, "%"):desire(nil, 5), col)
		local ch3 = scene:add(Node(10, "px", 100, "%"):desire(nil, 30), col)
		ch2.isGreedy = true
		col:allocateChildren() -- Needed after setting isGreedy.
		T.has(ch2, {h=50}, "Greedy child gets allocated all extra height.")
	end,
	function(scene) -- Make sure setGreedy re-allocates.
		local col = scene:add(Col(0, false, false, 100, "px", 100, "px"))
		local ch1 = scene:add(Node(10, "px", 10, "px"), col)
		local ch2 = scene:add(Node(10, "px", 100, "%"):desire(nil, 10):setGreedy(true), col)
		local ch3 = scene:add(Node(10, "px", 10, "px"), col)
		T.is(ch2.h, 80, "Greedy child gets allocated all extra height.")
		ch2:setGreedy(false)
		T.is(ch2.h, 10, "setGreedy(false) correctly re-allocates formerly-greedy child.")
	end,


	"GUI Row",
	function(scene) -- Homogeneous Row
		local row = scene:add(Row(0, true, nil, 100, "px", 100, "px"))
		local ch1 = scene:add(Node(100, "%", 10, "px"):desire(10, nil), row)
		local ch2 = scene:add(Node(100, "%", 10, "px"):desire(50, nil), row)
		T.has(ch1, {w=50}, "Homogeneous alloc to small child is correct.")
		T.has(ch2, {w=50}, "Homogeneous alloc to large child is correct.")
		local ch3 = scene:add(Node(100, "%", 10, "px"):desire(30, nil), row)
		T.has(ch1, {w=100/3}, "Homogeneous alloc to small child after adding new child is correct.")
		T.has(ch2, {w=100/3}, "Homogeneous alloc to large child after adding new child is correct.")
		T.has(ch3, {w=100/3}, "Homogeneous alloc to medium child after adding new child is correct.")
		local nonDesirous = scene:add(Node(50, "%", 50, "%"), row)
		row:allocateChildren()
		local w = 100/3
		T.ok(ch1.w == w and ch2.w == w and ch3.w == w, "Adding a non-desirous child does not take space from children in Row.")
		T.is(nonDesirous.lastAlloc.w, 100, "Non-desirous child is allocated full Row node height.")
		scene:remove(ch1)
		scene:remove(ch3)
		row:allocateChildren()
		T.has(ch2, {w=100}, "Homogeneous alloc to child after removing other children is correct.")
	end,
	function(scene) -- Heterogeneous Row - offsets
		local col = scene:add(Row(0, false, false, 100, "px", 100, "px"))
		local w1, w2 = 10, 40
		local ch1 = scene:add(Node(100, "%", 10, "px"):desire(w1, nil), col)
		local ch2 = scene:add(Node(100, "%", 10, "px"):desire(w2, nil), col)
		-- X offset is from the parent center to the child alloc center.
		T.has(ch1.lastAlloc, {x=0}, "Heterogeneous X offset alloc to child 1 is correct.")
		T.has(ch2.lastAlloc, {x=10}, "Heterogeneous X offset alloc to child 2 is correct.")
	end,
	function(scene) -- Heterogeneous Row - offsets - reverse dir
		local col = scene:add(Row(0, false, true, 100, "px", 100, "px"))
		local w1, w2 = 32, 10
		local ch1 = scene:add(Node(100, "%", 10, "px"):desire(w1, nil), col)
		local ch2 = scene:add(Node(100, "%", 10, "px"):desire(w2, nil), col)
		-- X offset is from the parent center to the child alloc center.
		T.has(ch1.lastAlloc, {x=100-32}, "Heterogeneous reverse-dir X offset alloc to child 1 is correct.")
		T.has(ch2.lastAlloc, {x=100-32-10}, "Heterogeneous reverse-dir X offset alloc to child 2 is correct.")
	end,
	function(scene) -- Heterogeneous Row
		local row = scene:add(Row(0, false, nil, 100, "px", 100, "px"))
		local ch1 = scene:add(Node(100, "%", 10, "px"):desire(10, nil), row)
		local ch2 = scene:add(Node(100, "%", 10, "px"):desire(50, nil), row)
		T.has(ch1, {w=10}, "Heterogeneous alloc to small child is correct.")
		T.has(ch2, {w=50}, "Heterogeneous alloc to medium child is correct.")
		-- Add another child that makes the child height sum to 200.
		local c3width = 200 - 10 - 50 -- 140
		local ch3 = scene:add(Node(100, "%", 10, "px"):desire(c3width, nil), row)
		T.has(ch1, {w=10/200*100}, "Squashed heterogeneous alloc to small child after adding new child is correct.")
		T.has(ch2, {w=50/200*100}, "Squashed heterogeneous alloc to medium child after adding new child is correct.")
		T.has(ch3, {w=140/200*100}, "Squashed heterogeneous alloc to oversize child after adding new child is correct.")
		scene:remove(ch1)
		scene:remove(ch3)
		row:allocateChildren()
		T.has(ch2, {w=50}, "Heterogeneous alloc to child after removing other children is correct.")
	end,
	function(scene) -- Row with greedy child
		local row = scene:add(Row(0, false, nil, 100, "px", 100, "px"))
		local ch1 = scene:add(Node(100, "%", 10, "px"):desire(20, nil), row)
		local ch2 = scene:add(Node(100, "%", 10, "px"):desire(5, nil), row)
		local ch3 = scene:add(Node(100, "%", 10, "px"):desire(30, nil), row)
		ch2.isGreedy = true
		row:allocateChildren() -- Needed after setting isGreedy.
		T.has(ch2, {w=50}, "Greedy child gets allocated all extra width.")
	end,
	function(scene) -- Make sure setGreedy re-allocates.
		local row = scene:add(Row(0, false, nil, 100, "px", 100, "px"))
		local ch1 = scene:add(Node(10, "px", 10, "px"), row)
		local ch2 = scene:add(Node(100, "%", 10, "px"):desire(10, nil):setGreedy(true), row)
		local ch3 = scene:add(Node(10, "px", 10, "px"), row)
		T.is(ch2.w, 80, "Greedy child gets allocated all extra height.")
		ch2:setGreedy(false)
		T.is(ch2.w, 10, "setGreedy(false) correctly re-allocates formerly-greedy child.")
	end,
}
