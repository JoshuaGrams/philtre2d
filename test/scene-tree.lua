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

	-- Check for duplicate init when adding sibling on init.
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
		T.is(table.concat(initOrder, ' '), '/Object/a /Object/c /Object/b /Object',
			"Adding a sibling in init should not cause objects to be initialized more than once.")
	end,

	-- Does this cause duplicate paths?
	function(scene)
		local obj = {}
		for i=1,4 do table.insert(obj, Object(10*(i-1), 0)) end
		scene:add(obj[1])  -- /Object
		scene:add(obj[2])  -- /Obejct2
		scene:add(obj[3])  -- /Object3
		-- Remove the first one that has a number attached.
		scene:remove(obj[2])
		-- Compact the child list.
		scene:update(1/60)
		scene:add(obj[4])  -- /Object4?
		scene:add(obj[2])  -- /Object5?
		for i=1,#obj-1 do
			for j=i+1,#obj do
				local ok = obj[i].path ~= obj[j].path
				local msg = 'obj['..i..'] and obj['..j..'] have different paths.'
				T.areOK(ok, obj[i].path, obj[j].path, msg)
			end
		end
	end,
}
