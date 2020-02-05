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

return {
	"SceneTree & DrawOrder",
	setup = function()  return SceneTree(layers, "a")  end,

	function(scene)
		local o1 = mod(Object(), {name = 1, draw = customDraw})
		local o2 = mod(Object(), {name = 2, draw = customDraw, layer = "b"})

		local function draw(group)
			drawn = ""
			scene:draw(group)
		end

		scene:add(o1)
		draw("a")
		T.is(drawn, "1", "object added, got drawn in default layer")

		scene:add(o2)
		draw("a")
		T.is(drawn, "1", "object added to non-drawn layer, didn't get drawn")
		T.is(o2.drawIndex, 1, "added object given correct drawIndex")

		draw("b")
		T.is(drawn, "2", "object drawn correctly in other layer group")

		o2:setVisible(false)
		draw("b")
		T.is(drawn, "", "object set hidden is not drawn")

		o2:setVisible(true)
		draw("b")
		T.is(drawn, "2", "object re-shown is drawn again")

		scene:setParent(o1, o2)
		draw("a")
		T.is(drawn, "", "object moved to parent with layer, not drawn in original layer")

		draw("b")
		T.is(drawn, "21", "child of obj with layer gets drawn in parent's layer, after parent")

		o2:setLayer("a")
		draw("b")
		T.is(drawn, "", "parent with layer moved (child with no layer set), nothing drawn in old layer")
		draw("a")
		T.is(drawn, "21", "both drawn in parent-child order in new layer")

		o1:setVisible(false)
		draw("a")
		T.is(drawn, "2", "child hidden, only parent is drawn")

		o2:setVisible(false)
		draw("a")
		T.is(drawn, "", "parent hidden, neither drawn")

		o1:setVisible(true)
		draw("a")
		T.is(drawn, "", "parent hidden, child shown, neither drawn")

		o2:setVisible(true)
		o1:setLayer("b")
		draw("a")
		T.is(drawn, "2", "child set to other layer, only parent drawn in its layer")
		draw("b")
		T.is(drawn, "1", "child drawn in its new layer")

		o2:setLayer("c")
		draw("b")
		T.is(drawn, "1", "parent layer changed, child with layer set is unmoved...")
	end
}
