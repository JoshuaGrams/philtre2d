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
	function(scene) -- Test that setters work and update things correctly.
		local col = scene:add(Col())
		local updated
		local function clear()
			updated = { trans=false, alloc=false, size=false, content=false }
		end
		clear()
		col.updateTransform = function(self, ...)
			Node.updateTransform(self, ...)
			updated.trans = true
		end
		col.allocateChildren = function(self, ...)
			local r = Node.allocateChildren(self, ...)
			updated.alloc = true
			return r
		end
		col.updateSize = function(self, ...)
			local r = Node.updateSize(self, ...)
			updated.size = true
			return r
		end
		col.updateContentSize = function(self, ...)
			local r = Node.updateContentSize(self, ...)
			updated.content = true
			return r
		end
		col:setSpacing(3)
		T.is(col.spacing, 3, "setSpacing(3) sets spacing to 3.")
		T.has(updated, {trans=true,alloc=true}, 'Things update correctly on setSpacing().')
		col:setSpacing()
		T.is(col.spacing, 0, "setSpacing([nil]) sets spacing to 0.")
		col:setEven(true)
		T.is(col.isEven, true, "setEven(true) sets isEven flag.")
		T.has(updated, {trans=true,alloc=true}, 'Things update correctly on setEven().')
		col:setEven(false)
		T.is(col.isEven, false, "setEven(false) sets isEven flag.")
		T.has(updated, {trans=true,alloc=true}, 'Things update correctly on setEven().')
		col:setReversed(true)
		T.is(col.isReversed, true, "setReversed(true) sets isEven flag.")
		T.has(updated, {trans=true,alloc=true}, 'Things update correctly on setReversed().')
		col:setReversed(false)
		T.is(col.isReversed, false, "setReversed(false) sets isEven flag.")
		T.has(updated, {trans=true,alloc=true}, 'Things update correctly on setReversed().')
	end,
	function(scene) -- Even Column
		local col = scene:add(Col(100, "px", 100, "px"):setEven(true))
		local ch1 = scene:add(Node(10, "px", 100, "%"):desire(nil, 10), col)
		local ch2 = scene:add(Node(10, "px", 100, "%"):desire(nil, 50), col)
		T.has(ch1, {h=50}, "Even height alloc to small child is correct.")
		T.has(ch2, {h=50}, "Even height alloc to large child is correct.")
		local ch3 = scene:add(Node(10, "px", 100, "%"):desire(nil, 30), col)
		T.has(ch1, {h=100/3}, "Even height alloc to small child after adding new child is correct.")
		T.has(ch2, {h=100/3}, "Even height alloc to large child after adding new child is correct.")
		T.has(ch3, {h=100/3}, "Even height alloc to medium child after adding new child is correct.")
		local nonDesirous = scene:add(Node(50, "%", 50, "%"), col)
		col:allocateChildren()
		local h = 100/3
		T.ok(ch1.h == h and ch2.h == h and ch3.h == h, "Adding a non-desirous child does not take space from children in Column.")
		T.is(nonDesirous.lastAlloc.h, 100, "Non-desirous child is allocated full Column node height.")
		scene:remove(ch1)
		scene:remove(ch3)
		col:allocateChildren()
		T.has(ch2, {h=100}, "Even alloc to child after removing other children is correct.")
	end,
	function(scene) -- Uneven Column - offsets
		local col = scene:add(Col(100, "px", 100, "px"))
		local h1, h2 = 10, 40
		local ch1 = scene:add(Node(10, "px", 100, "%"):desire(nil, h1), col)
		local ch2 = scene:add(Node(10, "px", 100, "%"):desire(nil, h2), col)
		T.has(ch1.lastAlloc, {y=0}, "Uneven Y offset alloc to child 1 is correct.")
		T.has(ch2.lastAlloc, {y=10}, "Uneven Y offset alloc to child 2 is correct.")
	end,
	function(scene) -- Uneven Column - offsets - reverse dir
		local col = scene:add(Col(100, "px", 100, "px"):setReversed(true))
		local h1, h2 = 32, 10
		local ch1 = scene:add(Node(10, "px", 100, "%"):desire(nil, h1), col)
		local ch2 = scene:add(Node(10, "px", 100, "%"):desire(nil, h2), col)
		T.has(ch1.lastAlloc, {y=100-32}, "Uneven reverse-dir Y offset alloc to child 1 is correct.")
		T.has(ch2.lastAlloc, {y=100-32-10}, "Uneven reverse-dir Y offset alloc to child 2 is correct.")
	end,
	function(scene) -- Uneven Column
		local col = scene:add(Col(100, "px", 100, "px"))
		local ch1 = scene:add(Node(10, "px", 100, "%"):desire(nil, 10), col)
		local ch2 = scene:add(Node(10, "px", 100, "%"):desire(nil, 50), col)
		T.has(ch1, {h=10}, "Uneven alloc to small child is correct.")
		T.has(ch2, {h=50}, "Uneven alloc to medium child is correct.")
		-- Add another child that makes the child height sum to 200.
		local c3height = 200 - 10 - 50 -- 140
		local ch3 = scene:add(Node(10, "px", 100, "%"):desire(nil, c3height), col)
		T.has(ch1, {h=10/200*100}, "Squashed heterogeneous alloc to small child after adding new child is correct.")
		T.has(ch2, {h=50/200*100}, "Squashed heterogeneous alloc to medium child after adding new child is correct.")
		T.has(ch3, {h=140/200*100}, "Squashed heterogeneous alloc to oversize child after adding new child is correct.")
		scene:remove(ch1)
		scene:remove(ch3)
		col:allocateChildren()
		T.has(ch2, {h=50}, "Uneven alloc to child after removing other children is correct.")
	end,
	function(scene) -- Column with greedy child
		local col = scene:add(Col(100, "px", 100, "px"))
		local ch1 = scene:add(Node(10, "px", 100, "%"):desire(nil, 20), col)
		local ch2 = scene:add(Node(10, "px", 100, "%"):desire(nil, 5), col)
		local ch3 = scene:add(Node(10, "px", 100, "%"):desire(nil, 30), col)
		ch2.isGreedy = true
		col:allocateChildren() -- Needed after setting isGreedy.
		T.has(ch2, {h=50}, "Greedy child gets allocated all extra height.")
	end,
	function(scene) -- Make sure setGreedy re-allocates.
		local col = scene:add(Col(100, "px", 100, "px"))
		local ch1 = scene:add(Node(10, "px", 10, "px"), col)
		local ch2 = scene:add(Node(10, "px", 100, "%"):desire(nil, 10):setGreedy(true), col)
		local ch3 = scene:add(Node(10, "px", 10, "px"), col)
		T.is(ch2.h, 80, "Greedy child gets allocated all extra height.")
		ch2:setGreedy(false)
		T.is(ch2.h, 10, "setGreedy(false) correctly re-allocates formerly-greedy child.")
	end,


	"GUI Row",
	function(scene) -- Test that setters work and update things correctly.
		local row = scene:add(Row())
		local updated
		local function clear()
			updated = { trans=false, alloc=false, size=false, content=false }
		end
		clear()
		row.updateTransform = function(self, ...)
			Node.updateTransform(self, ...)
			updated.trans = true
		end
		row.allocateChildren = function(self, ...)
			local r = Node.allocateChildren(self, ...)
			updated.alloc = true
			return r
		end
		row.updateSize = function(self, ...)
			local r = Node.updateSize(self, ...)
			updated.size = true
			return r
		end
		row.updateContentSize = function(self, ...)
			local r = Node.updateContentSize(self, ...)
			updated.content = true
			return r
		end
		row:setSpacing(3)
		T.is(row.spacing, 3, "setSpacing(3) sets spacing to 3.")
		T.has(updated, {trans=true,alloc=true}, 'Things update correctly on setSpacing().')
		row:setSpacing()
		T.is(row.spacing, 0, "setSpacing([nil]) sets spacing to 0.")
		row:setEven(true)
		T.is(row.isEven, true, "setEven(true) sets isEven flag.")
		T.has(updated, {trans=true,alloc=true}, 'Things update correctly on setEven().')
		row:setEven(false)
		T.is(row.isEven, false, "setEven(false) sets isEven flag.")
		T.has(updated, {trans=true,alloc=true}, 'Things update correctly on setEven().')
		row:setReversed(true)
		T.is(row.isReversed, true, "setReversed(true) sets isEven flag.")
		T.has(updated, {trans=true,alloc=true}, 'Things update correctly on setReversed().')
		row:setReversed(false)
		T.is(row.isReversed, false, "setReversed(false) sets isEven flag.")
		T.has(updated, {trans=true,alloc=true}, 'Things update correctly on setReversed().')
	end,
	function(scene) -- Even Row
		local row = scene:add(Row(100, "px", 100, "px"):setEven(true))
		local ch1 = scene:add(Node(100, "%", 10, "px"):desire(10, nil), row)
		local ch2 = scene:add(Node(100, "%", 10, "px"):desire(50, nil), row)
		T.has(ch1, {w=50}, "Even alloc to small child is correct.")
		T.has(ch2, {w=50}, "Even alloc to large child is correct.")
		local ch3 = scene:add(Node(100, "%", 10, "px"):desire(30, nil), row)
		T.has(ch1, {w=100/3}, "Even alloc to small child after adding new child is correct.")
		T.has(ch2, {w=100/3}, "Even alloc to large child after adding new child is correct.")
		T.has(ch3, {w=100/3}, "Even alloc to medium child after adding new child is correct.")
		local nonDesirous = scene:add(Node(50, "%", 50, "%"), row)
		row:allocateChildren()
		local w = 100/3
		T.ok(ch1.w == w and ch2.w == w and ch3.w == w, "Adding a non-desirous child does not take space from children in Row.")
		T.is(nonDesirous.lastAlloc.w, 100, "Non-desirous child is allocated full Row node height.")
		scene:remove(ch1)
		scene:remove(ch3)
		row:allocateChildren()
		T.has(ch2, {w=100}, "Even alloc to child after removing other children is correct.")
	end,
	function(scene) -- Uneven Row - offsets
		local col = scene:add(Row(100, "px", 100, "px"))
		local w1, w2 = 10, 40
		local ch1 = scene:add(Node(100, "%", 10, "px"):desire(w1, nil), col)
		local ch2 = scene:add(Node(100, "%", 10, "px"):desire(w2, nil), col)
		-- X offset is from the parent center to the child alloc center.
		T.has(ch1.lastAlloc, {x=0}, "Uneven X offset alloc to child 1 is correct.")
		T.has(ch2.lastAlloc, {x=10}, "Uneven X offset alloc to child 2 is correct.")
	end,
	function(scene) -- Uneven Row - offsets - reverse dir
		local col = scene:add(Row(100, "px", 100, "px"):setReversed(true))
		local w1, w2 = 32, 10
		local ch1 = scene:add(Node(100, "%", 10, "px"):desire(w1, nil), col)
		local ch2 = scene:add(Node(100, "%", 10, "px"):desire(w2, nil), col)
		-- X offset is from the parent center to the child alloc center.
		T.has(ch1.lastAlloc, {x=100-32}, "Uneven reverse-dir X offset alloc to child 1 is correct.")
		T.has(ch2.lastAlloc, {x=100-32-10}, "Uneven reverse-dir X offset alloc to child 2 is correct.")
	end,
	function(scene) -- Uneven Row
		local row = scene:add(Row(100, "px", 100, "px"))
		local ch1 = scene:add(Node(100, "%", 10, "px"):desire(10, nil), row)
		local ch2 = scene:add(Node(100, "%", 10, "px"):desire(50, nil), row)
		T.has(ch1, {w=10}, "Uneven alloc to small child is correct.")
		T.has(ch2, {w=50}, "Uneven alloc to medium child is correct.")
		-- Add another child that makes the child height sum to 200.
		local c3width = 200 - 10 - 50 -- 140
		local ch3 = scene:add(Node(100, "%", 10, "px"):desire(c3width, nil), row)
		T.has(ch1, {w=10/200*100}, "Squashed heterogeneous alloc to small child after adding new child is correct.")
		T.has(ch2, {w=50/200*100}, "Squashed heterogeneous alloc to medium child after adding new child is correct.")
		T.has(ch3, {w=140/200*100}, "Squashed heterogeneous alloc to oversize child after adding new child is correct.")
		scene:remove(ch1)
		scene:remove(ch3)
		row:allocateChildren()
		T.has(ch2, {w=50}, "Uneven alloc to child after removing other children is correct.")
	end,
	function(scene) -- Row with greedy child
		local row = scene:add(Row(100, "px", 100, "px"))
		local ch1 = scene:add(Node(100, "%", 10, "px"):desire(20, nil), row)
		local ch2 = scene:add(Node(100, "%", 10, "px"):desire(5, nil), row)
		local ch3 = scene:add(Node(100, "%", 10, "px"):desire(30, nil), row)
		ch2.isGreedy = true
		row:allocateChildren() -- Needed after setting isGreedy.
		T.has(ch2, {w=50}, "Greedy child gets allocated all extra width.")
	end,
	function(scene) -- Make sure setGreedy re-allocates.
		local row = scene:add(Row(100, "px", 100, "px"))
		local ch1 = scene:add(Node(10, "px", 10, "px"), row)
		local ch2 = scene:add(Node(100, "%", 10, "px"):desire(10, nil):setGreedy(true), row)
		local ch3 = scene:add(Node(10, "px", 10, "px"), row)
		T.is(ch2.w, 80, "Greedy child gets allocated all extra height.")
		ch2:setGreedy(false)
		T.is(ch2.w, 10, "setGreedy(false) correctly re-allocates formerly-greedy child.")
	end,
}
