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
		T.has(n.lastAlloc, {w=100,h=100}, "Node created with no arguments has correct lastAlloc size.")
	end,
	function(scene)
		local n = scene:add(Node()) -- Initial alloc is set to  0, 0, 100, 100 by default.
		T.has(n._toWorld, {x=0, y=0}, "World position is top right corner.")
		n:allocate(0, 0, 200, 200, 1)
		T.has(n._toWorld, {x=50, y=50}, "Transform updates on allocate if node position changes.")
		n:allocate(100, 60, 200, 200, 1)
		T.has(n._toWorld, {x=150, y=110}, "Transform updates if allocation offset changes.")
	end,
	function(scene) -- Test invalid mode constructor errors.
		local isSuccess, result = pcall(Node, 100, "invalid mode")
		T.ok(not isSuccess, 'Creating a Node with an invalid X mode causes an error')
		local isSuccess, result = pcall(Node, nil, nil, 100, "invalid mode")
		T.ok(not isSuccess, 'Creating a Node with an invalid Y mode causes an error')
		local isSuccess, result = pcall(Node, 1, "aspect", 1, "aspect")
		T.ok(not isSuccess, 'Creating a Node with "aspect" mode on both axes causes an error')
	end,
	function(scene) -- Check mode short name remapping.
		local xFns, yFns = Node.xScaleFuncs, Node.yScaleFuncs
		T.is(xFns[Node(100, "px"           ).modeX], xFns["pixels"], '"px" short X mode name remapping works.')
		T.is(yFns[Node(nil, nil, 100, "px" ).modeY], yFns["pixels"], '"px" short Y mode name remapping works.')
		T.is(xFns[Node(100, "u"            ).modeX], xFns["units"], '"u" short X mode name remapping works.')
		T.is(yFns[Node(nil, nil, 100, "u"  ).modeY], yFns["units"], '"u" short Y mode name remapping works.')
		T.is(xFns[Node(100, "%w"           ).modeX], xFns["percentw"], '"%w" short X mode name remapping works.')
		T.is(yFns[Node(nil, nil, 100, "%w" ).modeY], yFns["percentw"], '"%w" short Y mode name remapping works.')
		T.is(xFns[Node(100, "%h"           ).modeX], xFns["percenth"], '"%h" short X mode name remapping works.')
		T.is(yFns[Node(nil, nil, 100, "%h" ).modeY], yFns["percenth"], '"%h" short Y mode name remapping works.')
		T.is(xFns[Node(100, "rel"          ).modeX], xFns["relative"], '"rel" short X mode name remapping works.')
		T.is(yFns[Node(nil, nil, 100, "rel").modeY], yFns["relative"], '"rel" short Y mode name remapping works.')
		T.is(xFns[Node(100, "+"            ).modeX], xFns["relative"], '"+" short X mode name remapping works.')
		T.is(yFns[Node(nil, nil, 100, "+"  ).modeY], yFns["relative"], '"+" short Y mode name remapping works.')
		T.is(xFns[Node(100, "%"            ).modeX], xFns["percentw"], '"%" short X mode name remapping works.')
		T.is(yFns[Node(nil, nil, 100, "%"  ).modeY], yFns["percenth"], '"%" short Y mode name remapping works.')
	end,
	function(scene) -- Node should not allocate itself in constructor.
		local _Node = Node:extend() -- Create a subclass so we don't modify Node for other tests.
		local didAllocate = false
		function _Node.allocate()
			didAllocate = true
		end
		local n = _Node()
		T.ok(not didAllocate, 'Node doesn\'t allocate itself in constructor.')
	end,
	function(scene)
		local n = scene:add(Node(100, "%", 100, "%"))
		n:allocate(0, 0, 200, 200, 1)
		T.is(n.w, 200, "'percent' Node resizes (w) when allocated.")
		T.is(n.h, 200, "'percent' Node resizes (h) when allocated.")
		n:allocate(0, 0, 100, 100, 1)
		T.is(n.w, 100, "'percent' Node resizes (w) back down when allocated.")
		T.is(n.h, 100, "'percent' Node resizes (h) back down when allocated.")
	end,
	function(scene)
		-- modeY should default to modeX.
		local n = scene:add(Node(100, "pixels", 100, nil))
		T.has(n, {modeY="pixels"}, "Using constructor, modeY defaults to modeX.")
	end,
	function(scene)
		-- Child nodes should scale when parent is manually resized at runtime.
		local parent = scene:add(Node(100, "px", 100, "px"))
		local child = scene:add(Node(50, "%", 50, "%"), parent)
		parent:setSize(200, 200)
		T.is(child.w, 100, "Child scales (w) when parent is resized at runtime.")
		T.is(child.h, 100, "Child scales (h) when parent is resized at runtime.")
	end,
	function(scene)
		-- Runtime resize should persist after allocate is called from parent.
		local n = scene:add(Node(100, "%", 100, "%"))
		n:setSize(200, 200)
		n:allocate(0, 0, 200, 200, 1)
		T.is(n.w, 400, "Node keeps new size (w) when allocated after setSize().")
		T.is(n.h, 400, "Node keeps new size (h) when allocated after setSize().")
	end,
	function(scene)
		-- Runtime resize should persist after allocate is called from parent.
		local parent = scene:add(Node(100, "%", 100, "%"))
		local child = scene:add(Node(50, "%", 50, "%"), parent)
		parent:allocate(0, 0, 200, 200, 1)
		T.is(child.w, 100, "Child scales (w) when parent is reallocated at runtime.")
		T.is(child.h, 100, "Child scales (h) when parent is reallocated at runtime.")
	end,
	function(scene)
		local parent = scene:add(Node(100, "%", 100, "%"))
		parent:setSize(200, 200)
		local child = scene:add(Node(50, "%", 50, "%"), parent)
		T.is(child.w, 100, "Child added at runtime to resized parent resizes (w) when added.")
		T.is(child.h, 100, "Child added at runtime to resized parent resizes (h) when added.")
		parent:allocate(0, 0, 120, 120, 1)
		T.is(child.w, 120, "Runtime-added Child resizes (w) correctly when parent is reallocated.")
		T.is(child.h, 120, "Runtime-added Child resizes (h) correctly when parent is reallocated.")
		parent:allocate(0, 0, 50, 50, 1)
		T.is(child.w, 50, "Runtime-added Child resizes (w) correctly when parent is reallocated.")
		T.is(child.h, 50, "Runtime-added Child resizes (h) correctly when parent is reallocated.")
	end,
	function(scene)
		local n = scene:add(Node(100, "%", 100, "%"))
		n:allocate(0, 0, 200, 200, 1)
		n:setSize(50, 50)
		T.is(n.w, 100, "Setting size (w) when already resized works correctly.")
		T.is(n.h, 100, "Setting size (h) when already resized works correctly.")
	end,
	function(scene) -- Check width/height with padding.
		local n = scene:add(Node(100, "%", 100, "%", nil, nil, 10, 10))
		local child = scene:add(Node(100, "%", 100, "%"), n)
		T.is(child.w, 80, "Child w correct with parent padding (in set()).")
		T.is(child.h, 80, "Child h correct with parent padding (in set()).")
		n:setPad(20, 20)
		T.is(child.w, 60, "Child w correct with parent padding (in set()) after parent:setPad().")
		T.is(child.h, 60, "Child h correct with parent padding (in set()) after parent:setPad().")
		n:allocate(0, 0, 100, 100, 0.5)
		T.is(child.w, 80, "Child w correct with parent padding (in set()) after allocating with scale.")
		T.is(child.h, 80, "Child h correct with parent padding (in set()) after allocating with scale.")
	end,
	function(scene) -- Check x/y with padding
		local p = scene:add(Node():setPad(15, 4))
		local child = scene:add(Node(100, "%", 100, "%"), p)
		T.has(child._toWorld, {x=15, y=4}, "Child of padded parent has correct offset.")
		p:setPad(5, 7)
		T.has(child._toWorld, {x=5, y=7}, "Child has correct offset after parent padding changed.")
	end,
	function(scene) -- setAnchor & Pivot - make sure table and separate arg versions work.
		-- Test using constructor:
		local n = scene:add(Node(100, "px", 100, "px", {-1/3, 1/3}, {-2, 0.1}))
		T.has(n, {px=-1/3,py=1/3,ax=-2,ay=0.1}, "Using tables to set weird pivots & anchors in the constructor works.")
		n:setAnchor(1)
		T.is(n.ax, 1, "setAnchor - setting only X works.")
		n:setAnchor(nil, 2)
		T.is(n.ay, 2, "setAnchor - setting only Y works.")
		n:setPivot(-1)
		T.is(n.px, -1, "setPivot - setting only X works.")
		n:setPivot(nil, 0.5)
		T.is(n.py, 0.5, "setPivot - setting only Y works.")
	end,
	function(scene) -- Test pivots (with a center anchor)
		local function addNode(pivot)
			return scene:add(Node(100, "px", 100, "px", pivot or "C", "C"))
		end
		-- NOTE: World pos is always top left corner.
		local nw = addNode("NW") -- NW corner is at center of allocated space.
		T.has(nw._toWorld, {x=50, y=50}, "World pos of NW pivot node is correct.")
		local n = addNode("N")
		T.has(n._toWorld, {x=0, y=50}, "World pos of N pivot node is correct.")
		local ne = addNode("NE")
		T.has(ne._toWorld, {x=-50, y=50}, "World pos of NE pivot node is correct.")
		local e = addNode("E")
		T.has(e._toWorld, {x=-50, y=0}, "World pos of E pivot node is correct.")
		local se = addNode("SE")
		T.has(se._toWorld, {x=-50, y=-50}, "World pos of SE pivot node is correct.")
		local s = addNode("S")
		T.has(s._toWorld, {x=0, y=-50}, "World pos of S pivot node is correct.")
		local sw = addNode("SW")
		T.has(sw._toWorld, {x=50, y=-50}, "World pos of SW pivot node is correct.")
		local w = addNode("W")
		T.has(w._toWorld, {x=50, y=0}, "World pos of W pivot node is correct.")
		local c = addNode("C")
		T.has(c._toWorld, {x=0, y=0}, "World pos of C pivot node is correct.")
	end,
	function(scene) -- Test anchors (with center pivot)
		local function addNode(anchor)
			local n = scene:add(Node(100, "px", 100, "px", "C", anchor or "C"))
			n:allocate(0, 0, 200, 200, 1) -- 'Parent' is from 0,0 to 200,200.
			return n
		end
		local nw = addNode("NW")
		local n = addNode("N")
		local ne = addNode("NE")
		local e = addNode("E")
		local se = addNode("SE")
		local s = addNode("S")
		local sw = addNode("SW")
		local w = addNode("W")
		local c = addNode("C")
		-- Anchor pos should be from 0-200 in allocated space.
		T.has(nw, {anchorPosX=0, anchorPosY=0}, "Anchor pos of NW anchor node is correct.")
		T.has(n, {anchorPosX=100, anchorPosY=0}, "Anchor pos of N anchor node is correct.")
		T.has(ne, {anchorPosX=200, anchorPosY=0}, "Anchor pos of NE anchor node is correct.")
		T.has(e, {anchorPosX=200, anchorPosY=100}, "Anchor pos of E anchor node is correct.")
		T.has(se, {anchorPosX=200, anchorPosY=200}, "Anchor pos of SE anchor node is correct.")
		T.has(s, {anchorPosX=100, anchorPosY=200}, "Anchor pos of S anchor node is correct.")
		T.has(sw, {anchorPosX=0, anchorPosY=200}, "Anchor pos of SW anchor node is correct.")
		T.has(w, {anchorPosX=0, anchorPosY=100}, "Anchor pos of W anchor node is correct.")
		T.has(c, {anchorPosX=100, anchorPosY=100}, "Anchor pos of C anchor node is correct.")
		-- World pos should be top left corner of 100x100px node (centered at anchor pos).
		-- 		i.e: -50,-50 from anchor pos.
		T.has(nw._toWorld, {x=-50, y=-50}, "World pos of NW anchor node is correct.")
		T.has(n._toWorld, {x=50, y=-50}, "World pos of N anchor node is correct.")
		T.has(ne._toWorld, {x=150, y=-50}, "World pos of NE anchor node is correct.")
		T.has(e._toWorld, {x=150, y=50}, "World pos of E anchor node is correct.")
		T.has(se._toWorld, {x=150, y=150}, "World pos of SE anchor node is correct.")
		T.has(s._toWorld, {x=50, y=150}, "World pos of S anchor node is correct.")
		T.has(sw._toWorld, {x=-50, y=150}, "World pos of SW anchor node is correct.")
		T.has(w._toWorld, {x=-50, y=50}, "World pos of W anchor node is correct.")
		T.has(c._toWorld, {x=50, y=50}, "World pos of C anchor node is correct.")
	end,
	-- TODO vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
	function(scene) -- Hitcheck, with & without rotation.
		local n = scene:add(Node(100, "px", 100, "px", "NW", "NW")) -- Put NW corner at 0, 0 (default inintal alloc NW).
		T.ok(n:hitCheck(0, 0), "Hit-check is inclusive to top left pixel pos.")
		T.ok(not n:hitCheck(100, 100), "Hit-check is exclusive to bottom right pixel pos.")
		T.ok(n:hitCheck(0.0000001, 0.0000001), "Hit-check tiny bit more than top left pixel works.")
		T.ok(n:hitCheck(100 - 0.0000001, 100 - 0.0000001), "Hit-check tiny bit less than bottom right pixel works.")
		T.ok(n:hitCheck(25, 80), "Positive hit-check works.")
		T.ok(not n:hitCheck(-1, 20), "Negative hit-check works.")
		T.ok(n:hitCheck(50, 10), "(before rotation) Negative hitcheck works.")
		T.ok(not n:hitCheck(-45, 50), "(before rotation) Positive hitcheck works.")
		n:setAngle(math.rad(45)) -- Rotate 45° down.
		n:updateTransform()
		-- Remember: pivot is NW, rotating around that.
		T.ok(not n:hitCheck(50, 10), "Negative hitcheck works with rotation")
		T.ok(n:hitCheck(-45, 50), "Positive hitcheck works with rotation")
	end,
	function(scene) -- setPos - test with allocation and scale
		local n = scene:add(Node(100, "px", 100, "px", "NW", "NW")) -- NW corner at 0, 0.
		n:setPos(25, 35)
		n:updateTransform()
		T.has(n._toWorld, {x=25, y=35}, "setPos works")
		n:allocate(0, 0, 200, 200, 1) -- Node uses "none" mode, won't resize.
		T.has(n._toWorld, {x=25, y=35}, "Position not broken by allocation.")
		n:allocate(0, 0, 100, 100, 2) -- With scale - Pos is unaffected by scale
		T.has(n._toWorld, {x=25, y=35}, "Position unaffected by allocation scale.")
		n:setPos(20, 30)
		n:updateTransform()
		T.has(n._toWorld, {x=20, y=30}, "setPos after scaled allocation correctly works.")
		n:setPos(-10, -10, true) -- Relative
		n:updateTransform()
		T.has(n._toWorld, {x=20-10, y=30-10}, "setPos (relative) after scaled allocation works.")
	end,
	function(scene) -- setCenterPos - test with different anchors and pivots.)
		local w, h = 100, 100
		local hw, hh = w/2, h/2
		local n = scene:add(Node(w, "px", h, "px", "C", "C"))
		n:setCenterPos(100, 100):updateTransform()
		T.has(n._toWorld, {x=100-hw, y=100-hh}, "setCenterPos with C/C anchor/pivot works.")
		n:setPivot("NW")
		n:setCenterPos(49, -30):updateTransform()
		T.has(n._toWorld, {x=49-hw, y=-30-hh}, "setCenterPos with NW/C pivot/anchor works.")
		n:setPivot("S")
		n:setCenterPos(34, -2):updateTransform()
		T.has(n._toWorld, {x=34-hw, y=-2-hh}, "setCenterPos with S/C pivot/anchor works.")
		n:setPivot("E")
		n:setCenterPos(-105, 0.5):updateTransform()
		T.has(n._toWorld, {x=-105-hw, y=0.5-hh}, "setCenterPos with E/C pivot/anchor works.")
		n:setPivot("SW"):setAnchor("W")
		n:setCenterPos(11, 300):updateTransform()
		T.has(n._toWorld, {x=11-hw, y=300-hh}, "setCenterPos with SW/W pivot/anchor works.")
		n:setPivot("NE"):setAnchor("N")
		n:setCenterPos(18, 4):updateTransform()
		T.has(n._toWorld, {x=18-hw, y=4-hh}, "setCenterPos with NE/N pivot/anchor works.")
	end,
	function(scene) -- setCenterPos - test with scale and different anchors and pivots
		local parent = scene:add(Node(100, "px", 100, "px"))
		local child = scene:add(Node(10, "px", 10, "px"):setAngle(math.pi/3), parent)
		child:setCenterPos(32, 43)
		child:updateTransform()
		local wPos = { child:toWorld(child.w/2, child.h/2) }
		T.has(wPos, {32, 43}, "setCenterPos works on a rotated child.")
		local child2 = scene:add(Node(50, "px", 50, "px"):setPos(-10, -20), parent)
		child2:updateTransform()
		child2:setCenterPos(32, 43)
		child2:updateTransform()
		local wPos = { child:toWorld(child.w/2, child.h/2) }
		T.has(wPos, {32, 43}, "setCenterPos works on a child that had a pos before.")
	end,
	function(scene)
		local n = scene:add(Node(100, "px", 100, "px"):setPad(5))
		local testDebugDraw = function()
			n:debugDraw("default")
			scene:draw()
		end
		T.ok(pcall(testDebugDraw), "Debug draw runs without errors (just running to fill coverage).")
	end,
	function(scene) -- setScroll - check that children get offset
		local parent = scene:add(Node(100, "px", 100, "px"))
		parent:setScroll(5, 7)
		local child1 = scene:add(Node(10, "px", 10, "px"), parent)
		local child2 = scene:add(Node(10, "px", 10, "px"):setPos(10, 10), parent)
		local halfParentSize = 50
		local halfChildSize = 5
		local baseWPos = halfParentSize - halfChildSize
		T.has(child1._toWorld, {x=5+baseWPos,y=7+baseWPos}, "setScroll - first child gets offset when added.")
		T.has(child2._toWorld, {x=5+baseWPos+10,y=7+baseWPos+10}, "setScroll - second child with pos gets offset when added.")
		parent:setScroll(3, -1)
		T.has(child1._toWorld, {x=3+baseWPos,y=-1+baseWPos}, "setScroll - first child gets updated offset.")
		T.has(child2._toWorld, {x=3+baseWPos+10,y=-1+baseWPos+10}, "setScroll - second child with pos gets updated offset.")
	end,
	function(scene) -- setScroll - relative
		local parent = scene:add(Node(100, "px", 100, "px"))
		parent:setScroll(-5, -7)
		parent:allocate(0, 0, 100, 100, 2)
		local child = scene:add(Node(10, "px", 10, "px"), parent)
		parent:setScroll(-10, -10, true)
		local halfParentSize = 50
		local halfChildSize = 5
		local baseWPos = halfParentSize - halfChildSize
		T.has(child._toWorld, {x=-15+baseWPos,y=-17+baseWPos}, "setScroll - setting offset relative while scaled works.")
	end,
	function(scene) -- setMode
		local parent = scene:add(Node(100, "%", 100, "%"))
		local child = scene:add(Node(100, "%", 100, "%"), parent)
		parent:allocate(0, 0, 100, 100, 1)
		parent:setSize(200, 200)
		child:setMode("px", "px")
		T.is(child.w, 100, "setMode works - child w correct after changing mode after scaling.")
		T.is(child.h, 100, "setMode works - child h correct after changing mode after scaling.")
	end,
	function() -- test scale functions
		local xFn, yFn = Node.xScaleFuncs, Node.yScaleFuncs
		local self = { xParam = 5, yParam = 0.5 }
		-- "Pixels"
		T.is(xFn.pixels(self, 0, 0, 100, 100, 3), 5, "X Scale function 'pixels' works.")
		T.is(yFn.pixels(self, 0, 0, 100, 100, 3), 0.5, "Y Scale function 'pixels' works.")
		-- "Units"
		T.is(xFn.units(self, 0, 0, 100, 100, 3), 15, "X Scale function 'units' works.")
		T.is(yFn.units(self, 0, 0, 100, 100, 3), 1.5, "Y Scale function 'units' works.")
		-- "PercentW"
		self.xParam, self.yParam = 50, 100/3
		T.is(xFn.percentw(self, 0, 0, 36, 100, 3), 18, "X Scale function 'percentw' works.")
		T.isNearly(yFn.percentw(self, 0, 0, 36, 100, 3), 12, "Y Scale function 'percentw' works.")
		-- "PercentH"
		T.is(xFn.percenth(self, 0, 0, 36, 100, 3), 50, "X Scale function 'percenth' works.")
		T.is(yFn.percenth(self, 0, 0, 36, 100, 3), 100/3, "Y Scale function 'percenth' works.")
		-- "Pixels/Aspect"
		self.xParam, self.yParam = 40, 4/3
		self.w = 40
		T.is(yFn.aspect(self, 0, 0, 100, 100, 1), 30, "Y Scale function 'aspect' with 'pixels' X works.")
		-- "Aspect/PercentW"
		self.xParam, self.yParam = 3/4, 40
		self.h = 40
		T.is(xFn.aspect(self, 0, 0, 100, 200, 1), 30, "X Scale function 'aspect' with 'pixels' Y works.")
		-- "Relative"
		self.xParam, self.yParam = -15, 2.5
		T.is(xFn.relative(self, 0, 0, 100, 200, 1), 100-15, "X Scale function 'relative' works.")
		T.is(yFn.relative(self, 0, 0, 100, 200, 1), 200+2.5, "Y Scale function 'relative' works.")
	end,
	function(scene) -- Test setGreedy()
		local n = Node()
		n:setGreedy(true)
		T.is(n.isGreedy, true, "setGreedy(true) sets greedy flag.")
		n:setGreedy(false)
		T.is(n.isGreedy, false, "setGreedy(false) sets greedy flag.")
	end,
	function(scene) -- Test if setters update things correctly.
		local n = Node()
		local ch = Node()
		n.children = { ch }
		scene:add(n) -- Must be in tree to test if updateTransform fires.
		local updated
		local function clear()
			updated = { trans=false, alloc=false, size=false, content=false }
		end
		clear()
		n.updateTransform = function(self, ...)
			Node.updateTransform(self, ...)
			updated.trans = true
		end
		n.allocateChildren = function(self, ...)
			local r = Node.allocateChildren(self, ...)
			updated.alloc = true
			return r
		end
		n.updateSize = function(self, ...)
			local r = Node.updateSize(self, ...)
			updated.size = true
			return r
		end
		n.updateContentSize = function(self, ...)
			local r = Node.updateContentSize(self, ...)
			updated.content = true
			return r
		end
		n:setSize(50, 50)
		T.has(updated, {trans=true,alloc=true,size=true,content=true}, 'Things update correctly on setSize().')
		clear()
		n:setPos(10, 5)
		T.has(updated, {trans=true}, 'Things update correctly on setPos().')
		clear()
		n:setCenterPos(200, 150)
		T.has(updated, {trans=true}, 'Things update correctly on setCenterPos().')
		clear()
		n:setAngle(1)
		T.has(updated, {trans=true}, 'Things update correctly on setAngle().')
		clear()
		n:setScroll(-5, -7)
		T.has(updated, {trans=true,content=true,alloc=true}, 'Things update correctly on setScroll().')
		clear()
		n:setAnchor("SE")
		T.has(updated, {trans=true}, 'Things update correctly on setAnchor().')
		clear()
		n:setPivot("W")
		T.has(updated, {trans=true}, 'Things update correctly on setPivot().')
		clear()
		n:setPad(7, 6.5)
		T.has(updated, {trans=true,content=true,alloc=true}, 'Things update correctly on setPad().')
		clear()
		n._debug = true
		n:setMode('rel', 'rel') -- Need to use modes that will actually change its size.
		T.has(updated, {trans=true,alloc=true,size=true,content=true}, 'Things update correctly on setMode().')
		clear()
	end,
}
