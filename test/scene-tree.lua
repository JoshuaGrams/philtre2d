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

return {
	"SceneTree/Object",
	setup = function() return SceneTree() end,
	function(scene)
		local initOrder = {}
		local function init(o)
			table.insert(initOrder, o.path)
		end

		local a = mod(Object(0, 0), {name = 'a'})
		local b = mod(Object(10, 0), {name = 'b', init = init})
		local c = mod(Object(20, 0), {name = 'c', init = init})
		container = mod(Object(0, 0), {init = init, children = {a, b}})

		a.init = function(o)
			init(o)
			scene:add(c, o.parent)
		end

		scene:add(container)
		T.is(table.concat(initOrder, ' '), '/Object/a /Object/c /Object/b /Object', "Adding a sibling in init should not cause objects to be initialized more than once.")
	end
}
