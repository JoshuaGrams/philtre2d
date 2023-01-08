local base = (...):gsub('[^%.]+%.[^%.]+$', '')
local T = require(base .. 'lib.simple-test')

local SceneTree = require(base .. 'objects.SceneTree')
matrix = require(base .. 'core.matrix')
local gui = require(base .. 'objects.gui.all')
local Node = gui.Node

return {
	"GUI Node",
	setup = function() return SceneTree() end,
	function()
		if not T.ok(pcall(Node), "Can create node using no arguments.") then
			return
		end
		local n = Node()
		T.is(n.w, 100, "Node created with no arguments has default w.")
		T.is(n.h, 100, "Node created with no arguments has default h.")
		T.has(n.designRect, {w=100,h=100}, "Node created with no arguments has default design size.")
		T.has(n.lastAlloc, {w=100,h=100,designW=100,designH=100}, "Node created with no arguments has correct lastAlloc size.")
	end,
	function(scene)
		local n = scene:add(Node(100, 100, nil, nil, "stretch", "stretch"))
		n:allocate(0, 0, 200, 200, 100, 100, 1)
		T.is(n.w, 200, "'stretch' Node resizes (w) when allocated.")
		T.is(n.h, 200, "'stretch' Node resizes (h) when allocated.")
		n:allocate(0, 0, 100, 100, 100, 100, 1)
		T.is(n.w, 100, "'stretch' Node resizes (w) back down when allocated.")
		T.is(n.h, 100, "'stretch' Node resizes (h) back down when allocated.")
	end,
	function(scene)
		-- modeY should default to modeX.
		local n = scene:add(Node(100, 100, "C", "C", "cover"))
		T.has(n, {modeY="cover"}, "Using constructor, modeY defaults to modeX.")
	end,
	function(scene)
		-- Child nodes should scale when parent is manually resized at runtime.
		local parent = scene:add(Node(100, 100))
		local child = scene:add(Node(50, 50, nil, nil, "stretch", "stretch"), parent)
		parent:setSize(200, 200)
		T.is(child.w, 100, "Child scales (w) when parent is resized at runtime.")
		T.is(child.h, 100, "Child scales (h) when parent is resized at runtime.")
	end,
	function(scene)
		-- Runtime resize should persist after allocate is called from parent.
		local n = scene:add(Node(100, 100, nil, nil, "stretch", "stretch"))
		n:setSize(200, 200)
		n:allocate(0, 0, 200, 200, 100, 100, 1)
		T.is(n.w, 400, "Node keeps new size (w) when allocated after setSize().")
		T.is(n.h, 400, "Node keeps new size (h) when allocated after setSize().")
	end,
	function(scene)
		-- Runtime resize should persist after allocate is called from parent.
		local parent = scene:add(Node(100, 100, nil, nil, "stretch", "stretch"))
		local child = scene:add(Node(50, 50, nil, nil, "stretch", "stretch"), parent)
		parent:allocate(0, 0, 200, 200, 100, 100, 1)
		T.is(child.w, 100, "Child scales (w) when parent is reallocated at runtime.")
		T.is(child.h, 100, "Child scales (h) when parent is reallocated at runtime.")
	end,
	function(scene)
		local parent = scene:add(Node(100, 100, nil, nil, "stretch", "stretch"))
		parent:setSize(200, 200)
		local child = scene:add(Node(50, 50, nil, nil, "stretch", "stretch"), parent)
		T.is(child.w, 100, "Child added at runtime to resized parent resizes (w) when added.")
		T.is(child.h, 100, "Child added at runtime to resized parent resizes (h) when added.")
		parent:allocate(0, 0, 120, 120, 100, 100, 1)
		T.is(child.w, 120, "Runtime-added Child resizes (w) correctly when parent is reallocated.")
		T.is(child.h, 120, "Runtime-added Child resizes (h) correctly when parent is reallocated.")
		parent:allocate(0, 0, 50, 50, 100, 100, 1)
		T.is(child.w, 50, "Runtime-added Child resizes (w) correctly when parent is reallocated.")
		T.is(child.h, 50, "Runtime-added Child resizes (h) correctly when parent is reallocated.")
	end,
	function(scene)
		local n = scene:add(Node(100, 100, nil, nil, "stretch", "stretch"))
		n:allocate(0, 0, 200, 200, 100, 100, 1)
		n:setSize(120, 120, true)
		T.is(n.w, 240, "Setting design size (w) when already resized works correctly.")
		T.is(n.h, 240, "Setting design size (h) when already resized works correctly.")
	end,
	function(scene) -- Check padding stuff.
		local n = scene:add(Node(100, 100, nil, nil, "stretch", "stretch", 10, 10))
		local child = scene:add(Node(100, 100, nil, nil, "fill", "fill"), n)
		T.is(child.w, 80, "Child w correct with parent padding (in set()).")
		T.is(child.h, 80, "Child h correct with parent padding (in set()).")
		n:setPad(20, 20)
		T.is(child.w, 60, "Child w correct with parent padding (in set()) after parent:setPad().")
		T.is(child.h, 60, "Child h correct with parent padding (in set()) after parent:setPad().")
		n:allocate(0, 0, 100, 100, 100, 100, 0.5)
		T.is(child.w, 80, "Child w correct with parent padding (in set()) after allocating with scale.")
		T.is(child.h, 80, "Child h correct with parent padding (in set()) after allocating with scale.")
	end,
	function(scene) -- Hitcheck, with & without rotation.
		local n = scene:add(Node(100, 100, "NW", "C")) -- Put NW corner at 0, 0 (screen NW).
		T.ok(n:hitCheck(25, 80), "Positive hit-check works.")
		T.ok(not n:hitCheck(-1, 20), "Negative hit-check works.")
		T.ok(n:hitCheck(50, 10), "(before rotation) Negative hitcheck works.")
		T.ok(not n:hitCheck(-45, 50), "(before rotation) Positive hitcheck works.")
		n:setAngle(math.pi/4)
		n:updateTransform()
		-- Remember: pivot is NW, rotating around that.
		T.ok(not n:hitCheck(50, 10), "Negative hitcheck works with rotation")
		T.ok(n:hitCheck(-45, 50), "Positive hitcheck works with rotation")
	end,
	function(scene) -- setPos - test with allocation and scale
		local n = scene:add(Node(100, 100, "NW", "C")) -- NW corner at 0, 0.
		n:setPos(25, 35)
		n:updateTransform()
		T.is(n._toWorld.x, 25 + 50, "setPos (x) works")
		T.is(n._toWorld.y, 35 + 50, "setPos (y) works")
		n:allocate(0, 0, 200, 200, 100, 100, 1) -- Node uses "none" mode, won't resize.
		T.is(n._toWorld.x, 25 + 50, "setPos (x) works after allocation.")
		T.is(n._toWorld.y, 35 + 50, "setPos (y) works after allocation.")
		n:allocate(0, 0, 100, 100, 100, 100, 2) -- Uses "none" mode, -will- scale w/h.
		T.is(n._toWorld.x, (25 + 50)*2, "setPos (x) works after allocation with scale.")
		T.is(n._toWorld.y, (35 + 50)*2, "setPos (y) works after allocation with scale.")
		n:setPos(20, 30)
		n:updateTransform()
		T.is(n._toWorld.x, 20 + (50)*2, "setPos for current pos after allocation scale works (x).")
		T.is(n._toWorld.y, 30 + (50)*2, "setPos for current pos after allocation scale works (y).")
		n:setPos(20, 30, true)
		n:updateTransform()
		T.is(n._toWorld.x, (20 + 50)*2, "setPos for design pos after allocation scale works (x).")
		T.is(n._toWorld.y, (30 + 50)*2, "setPos for design pos after allocation scale works (y).")
		n:setPos(-10, -10, false, true) -- Relative
		n:updateTransform()
		T.is(n._toWorld.x, (20 + 50)*2 - 10, "setPos (relative) for current pos after allocation scale works (x).")
		T.is(n._toWorld.y, (30 + 50)*2 - 10, "setPos (relative) for current pos after allocation scale works (y).")
	end,
	function(scene) -- setCenterPos - test with scale and different anchors and pivots
		local parent = scene:add(Node(100, 100))
		local child = scene:add(Node(10, 10):setAngle(math.pi/3), parent)
		child:setCenterPos(32, 43)
		child:updateTransform()
		T.has(child._toWorld, {x=32, y=43}, "setCenterPos works on a rotated child.")
		local child2 = scene:add(Node(50, 50):setPos(-10, -20), parent)
		child2:updateTransform()
		child:setCenterPos(32, 43)
		child:updateTransform()
		T.has(child._toWorld, {x=32, y=43}, "setCenterPos works on a child that had a pos before.")
	end,
	function(scene)
		local n = scene:add(Node(100, 100):setPad(5))
		local testDebugDraw = function()
			n:debugDraw("default")
			scene:draw()
		end
		T.ok(pcall(testDebugDraw), "Debug draw runs without errors (just running to fill coverage).")
	end,
	function(scene) -- setOffset - check that children get offset
		local parent = scene:add(Node(100, 100))
		parent:setOffset(5, 7)
		local child1 = scene:add(Node(10, 10), parent)
		local child2 = scene:add(Node(10, 10):setPos(10, 10), parent)
		T.has(child1._toWorld, {x=5,y=7}, "setOffset - first child gets offset when added.")
		T.has(child2._toWorld, {x=15,y=17}, "setOffset - second child with pos gets offset when added.")
		parent:setOffset(3, -1)
		T.has(child1._toWorld, {x=3,y=-1}, "setOffset - first child gets updated offset.")
		T.has(child2._toWorld, {x=13,y=9}, "setOffset - second child with pos gets updated offset.")
		-- TODO: check setOffset with relative mode.
	end,
	function(scene) -- setOffset - relative
		local parent = scene:add(Node(100, 100))
		parent:setOffset(-5, -7)
		parent:allocate(0, 0, 100, 100, 100, 100, 2)
		local child = scene:add(Node(10, 10), parent)
		parent:setOffset(-10, -10, true)
		T.has(child._toWorld, {x=-15,y=-17}, "setOffset - setting offset relative while scaled works.")
	end,
	function(scene) -- setAnchor & Pivot - make sure table and separate arg versions work.
		-- Test using constructor:
		local n = scene:add(Node(100, 100, {-1/3, 1/3}, {-2, 0.1}))
		T.has(n, {px=-1/3,py=1/3,ax=-2,ay=0.1}, "Using tables to set weird pivots & anchors in the constructor works.")
		n:setAnchor(1)
		T.is(n.ax, 1, "setAnchor - just setting X works.")
		n:setAnchor(nil, 2)
		T.is(n.ay, 2, "setAnchor - just setting Y works.")
		n:setPivot(-1)
		T.is(n.px, -1, "setPivot - just setting X works.")
		n:setPivot(nil, 0.5)
		T.is(n.py, 0.5, "setPivot - just setting Y works.")
	end,
	function(scene) -- setMode
		local parent = scene:add(Node(100, 100, nil, nil, "stretch", "stretch"))
		local child = scene:add(Node(100, 100, nil, nil, "stretch", "stretch"), parent)
		parent:setSize(200, 200)
		child:setMode("none", "none")
		T.is(child.w, 100, "setMode works - child w correct after changing mode after scaling.")
		T.is(child.h, 100, "setMode works - child h correct after changing mode after scaling.")
	end,
	function(scene) -- test scale functions
		-- "fit" and "cover" are the only ones not covered so far.
		local scale = Node._scaleFuncs
		local sx, sy = scale.fit(nil, 100, 100, 200, 100, nil)
		T.is(sx, 0.5, "Fit scale X is correct.")
		T.is(sy, 0.5, "Fit scale Y is correct.")
		local sx, sy = scale.fit(nil, 300, 600, 200, 100, nil)
		T.is(sx, 1.5, "Fit scale X (2) is correct.")
		T.is(sy, 1.5, "Fit scale Y (2) is correct.")

		local sx, sy = scale.cover(nil, 100, 100, 200, 100, nil)
		T.is(sx, 1, "Cover scale X is correct.")
		T.is(sy, 1, "Cover scale Y is correct.")
		local sx, sy = scale.cover(nil, 300, 600, 200, 100, nil)
		T.is(sx, 6, "Cover scale X (2) is correct.")
		T.is(sy, 6, "Cover scale Y (2) is correct.")
	end,
}
