local base = (...):gsub('[^%.]+.[^%.]+$', '')
local T = require 'lib.simple-test'

local SceneTree = require(base .. 'scene-tree')
local Object = require(base .. 'Object')

local function mod(obj, props)
	for name,prop in pairs(props) do
		obj[name] = prop
	end
	return obj
end

local layers = {
	a = { "a" },
	b = { "b" },
	c = { "c" }
}

local drawn = ""

local function customDraw(self)
	drawn = drawn .. self.name
end

local function draw(scene, group)
	drawn = ""
	scene:draw(group)
end

return {
	"SceneTree & DrawOrder",
	setup = function()  return SceneTree(layers, "a")  end,

	function(scene)
		local o1 = mod(Object(), {name = 1, draw = customDraw})
		local o2 = mod(Object(), {name = 2, draw = customDraw, layer = "b"})

		scene:add(o1)
		draw(scene, "a")
		T.is(drawn, "1", "object added, got drawn in default layer")

		scene:add(o2)
		draw(scene, "a")
		T.is(drawn, "1", "object added to non-drawn layer, didn't get drawn")
		T.is(o2.drawIndex, 1, "added object given correct drawIndex")

		draw(scene, "b")
		T.is(drawn, "2", "object drawn correctly in other layer group")

		o2:setVisible(false)
		draw(scene, "b")
		T.is(drawn, "", "object set hidden is not drawn")

		o2:setVisible(true)
		draw(scene, "b")
		T.is(drawn, "2", "object re-shown is drawn again")

		scene:setParent(o1, o2)
		draw(scene, "a")
		T.is(drawn, "", "object moved to parent with layer, not drawn in original layer")

		draw(scene, "b")
		T.is(drawn, "21", "child of obj with layer gets drawn in parent's layer, after parent")

		o2:setLayer("a")
		draw(scene, "b")
		T.is(drawn, "", "parent with layer moved (child with no layer set), nothing drawn in old layer")
		draw(scene, "a")
		T.is(drawn, "21", "both drawn in parent-child order in new layer")

		o1:setVisible(false)
		draw(scene, "a")
		T.is(drawn, "2", "child hidden, only parent is drawn")

		o2:setVisible(false)
		draw(scene, "a")
		T.is(drawn, "", "parent hidden, neither drawn")

		o1:setVisible(true)
		draw(scene, "a")
		T.is(drawn, "", "parent hidden, child shown, neither drawn")

		o2:setVisible(true)
		o1:setLayer("b")
		draw(scene, "a")
		T.is(drawn, "2", "child set to other layer, only parent drawn in its layer")
		draw(scene, "b")
		T.is(drawn, "1", "child drawn in its new layer")

		o2:setLayer("c")
		draw(scene, "b")
		T.is(drawn, "1", "parent layer changed, child with layer set is unmoved...")
	end,
	function(scene)
		local o1 = mod(Object(), {name = 1, draw = customDraw, visible = false})
		local o2 = mod(Object(), {name = 2, draw = customDraw})
		scene:add(o1)
		scene:add(o2, o1)
		draw(scene, "a")
		T.is(drawn, "", "add to hidden parent, child not drawn")
	end,
	function(scene)
		local init = function(self)
			local o3 = mod(Object(), {name = 3, draw = customDraw})
			scene:add(o3, self)
		end
		local script = {init = init}
		local o1 = mod(Object(), {name = 1, draw = customDraw, script = {script}})
		scene:add(o1)
		draw(scene, "a")
		T.is(drawn, "31", "add children on init, they don't get drawn twice")
	end,
	function(scene)
		local parent, child = Object(), Object()
		parent.children = { child }
		scene:add(parent)
		scene:update(0)
		scene:remove(child)
		local success, err = pcall(scene.remove, scene, parent)
		T.is(err, nil, "can remove child and then parent in same frame")
	end,
	function(scene)
		local parent, child = Object(), Object()
		parent.children = { child }
		scene:add(parent)
		scene:update(0)

		scene:remove(parent)
		local success, err = pcall(scene.remove, scene, child)
		T.is(err, nil, "can remove parent and then child in same frame")
		-- Grandparent will be nil, and if any ancestor reference is nil
		-- then DrawOrder can't recurse up to find the layer.
	end
}
