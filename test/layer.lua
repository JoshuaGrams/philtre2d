local base = (...):gsub('[^%.]+.[^%.]+$', '')
local T = require 'lib.simple-test'

local Layer = require(base .. 'render.layer')
local M = require(base .. 'modules.matrix')
local Object = require(base .. 'objects.Object')

local function recordCall(called, name)
	table.insert(called, name)
end

local function mod(obj, props)
	for name,prop in pairs(props) do
		obj[name] = prop
	end
	return obj
end

return {
	"Layers",
	setup = function()
		return M.identity
	end,
	function(m)
		local called = {}
		local layer = Layer()
		local names = { 'first', 'second', 'third', 'fourth' }
		for _,name in ipairs(names) do
			layer:addFunction(m, recordCall, called, name)
		end
		layer:draw()
		T.is(#called, #names, "called correct number of functions")
		T.has(called, names, "should call functions in order")

		called = {}
		layer:clear()
		layer:addFunction(m, recordCall, called, 'fifth')
		layer:addFunction(m, recordCall, called, 'sixth')
		layer:draw()
		T.is(#called, 2, "can have fewer functions after being cleared")
		T.has(called, {
			'fifth', 'sixth'
		}, "should call only new functions after being cleared")

		called = {}
		layer:clear()
		layer:addFunction(m, recordCall, called, 'seventh')
		layer:addFunction(m, recordCall, called, 'eighth')
		layer:addFunction(m, recordCall, called, 'ninth')
		layer:addFunction(m, recordCall, called, 'tenth')
		layer:addFunction(m, recordCall, called, 'eleventh')
		layer:addFunction(m, recordCall, called, 'twelfth')
		layer:draw()
		T.is(#called, 6, "can have more functions after being cleared")
		T.has(called, {
			'seventh', 'eighth', 'ninth',
			'tenth', 'eleventh', 'twelfth'
		}, "should call only new functions after being cleared")
	end,
	function()
		local layer = Layer()
		local obj = mod(Object(), {name = 1})
		layer:addObject(obj)
		T.ok(layer[1] and layer[1][2] == obj, "added object")
		T.ok(layer.n == 1, "  layer.n == 1")
		T.ok(obj.drawIndex == 1, "  object's drawIndex == 1")

		local obj2 = mod(Object(), {name = 2})
		local obj3 = mod(Object(), {name = 3})
		local obj4 = mod(Object(), {name = 4})
		local obj5 = mod(Object(), {name = 5})
		layer:addObject(obj2)
		layer:addObject(obj3)
		layer:addObject(obj4)
		T.ok(layer[2][2] == obj2 and layer[3][2] == obj3 and layer[4][2] == obj4,"added 3 more objects")
		T.ok(layer.n == 4, "  layer.n == 4")
		T.ok(obj2.drawIndex == 2 and obj3.drawIndex == 3 and obj4.drawIndex == 4, "  objects' drawIndices are 2, 3, and 4")

		layer:removeObject(obj2)
		T.ok(layer[1] and layer[3] and layer[4] and (layer[2] == false), "removed object, its index is now false, all others still exist")
		T.ok(layer.dirty == true, "  layer is now flagged as dirty")
		T.ok(layer.n == 4, "  layer.n is still 4")

		layer:addObject(obj5)
		T.ok(layer[5][2] == obj5 and layer.n == 5, "added a 5th object, it is at index 5 and layer.n is now 5")
		T.ok(obj5.drawIndex == 5, "  5th object's drawIndex is 5")

		layer:refreshIndices()
		T.note("layer:refreshIndices()")
		T.ok(layer[2] ~= false, "layer's second element is no longer false")
		T.ok(layer[2][2] == obj3, "  it is now object 3")
		T.ok(layer.n == 4, "refreshed indices, layer.n is now 4")
		T.ok(
			obj.drawIndex == 1 and obj3.drawIndex == 2 and obj4.drawIndex == 3 and obj5.drawIndex == 4,
			"objects' drawIndices have been updated and to be consecutive with no gaps"
		)

		layer:removeObject(obj3)
		layer:removeObject(obj4)
		T.ok(layer[2] == false and layer[3] == false and layer[1] and layer[4], "removed two objects, their indices are now false, others still exist")
		T.ok(layer.n == 4, "layer.n is still 4")

		layer:refreshIndices()
		T.note("layer:refreshIndices() -- two consecutive removed objects")
		T.ok(layer[2] ~= false and layer[3] ~= false, "refresh indices, layer[2] and layer[3] are no longer false")
		T.ok(layer[2][2] == obj5 and layer[3] == nil and layer[4] == nil, "second item is now object-5, 3rd and 4th items are now nil.")
		T.ok(layer.n == 2, "layer.n is now 2")
		T.ok(obj.drawIndex == 1 and obj5.drawIndex == 2, "objects' drawIndices are updated correctly")
	end
}
