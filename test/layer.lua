local base = (...):gsub('[^%.]+.[^%.]+$', '')
local T = require 'lib.simple-test'

local Layer = require(base .. 'render.layer')
local M = require(base .. 'core.matrix')
local Object = require(base .. 'objects.Object')

local function identityM()
	return M.copy(M.identity)
end

local function recorderFn(called, name)
	table.insert(called, name)
end

local _called
local function recorderDraw(self)
	table.insert(_called, self.name)
end

local function makeNumberedObject(i)
	local obj = Object()
	obj.name = i
	obj.draw = recorderDraw
	return obj
end

local function makeObjects(i1, i2)
	local list = {}
	for i=i1,i2 do
		table.insert(list, makeNumberedObject(i))
	end
	return list
end

local function addObjects(layer, objects)
	for i,obj in ipairs(objects) do  layer:addObject(obj)  end
	return objects
end

return {
	"Layers",
	function()
		_called = {}
		local layer = Layer()
		local names = { 'first', 'second', 'third', 'fourth' }
		for _,name in ipairs(names) do
			layer:addFunction(identityM(), recorderFn, _called, name)
		end
		layer:draw()
		T.is(#_called, #names, "called correct number of functions")
		T.has(_called, names, "called functions in order") -- T.has checks matching key-value pairs.

		_called = {}
		layer:clear()
		layer:draw()
		T.is(next(_called), nil, "clear removed everything")

		_called = {}
		layer:addFunction(identityM(), recorderFn, _called, 'fifth')
		layer:addFunction(identityM(), recorderFn, _called, 'sixth')
		layer:draw()
		T.is(#_called, 2, "can have fewer functions after being cleared")
		T.has(_called, {
			'fifth', 'sixth'
		}, "should call only new functions after being cleared")

		_called = {}
		layer:clear()
		layer:addFunction(identityM(), recorderFn, _called, 'seventh')
		layer:addFunction(identityM(), recorderFn, _called, 'eighth')
		layer:addFunction(identityM(), recorderFn, _called, 'ninth')
		layer:addFunction(identityM(), recorderFn, _called, 'tenth')
		layer:addFunction(identityM(), recorderFn, _called, 'eleventh')
		layer:addFunction(identityM(), recorderFn, _called, 'twelfth')
		layer:draw()
		T.is(#_called, 6, "can have more functions after being cleared")
		T.has(_called, {
			'seventh', 'eighth', 'ninth',
			'tenth', 'eleventh', 'twelfth'
		}, "should call only new functions after being cleared")
	end,
	function()
		-- Make sure object has a numeric drawIndex and gets drawn.
		local layer = Layer()
		local obj = makeObjects(1, 1)[1]
		layer:addObject(obj)
		T.ok(tonumber(obj.drawIndex), "Added object has numeric drawIndex")

		_called = {}
		layer:draw()
		T.has(_called, {1}, "Added object was drawn")

		-- Make sure consecutively added objects have consecutive drowIndices and are drawn in order.
		local objs = addObjects(layer, makeObjects(2, 5))
		table.insert(objs, 1, obj)
		_called = {}
		local inOrder =
			objs[1].drawIndex < objs[2].drawIndex and
			objs[2].drawIndex < objs[3].drawIndex and
			objs[3].drawIndex < objs[4].drawIndex and
			objs[4].drawIndex < objs[5].drawIndex
		T.ok(inOrder, "Added more objects and their drawIndices are in ascending order")

		layer:draw()
		T.has(_called, {1,2,3,4,5}, "Added more objects and they are drawn in order")

		-- Make sure objects still get drawn in order after second object is removed.
		layer:removeObject(objs[2])
		T.ok(not objs[2].drawIndex, "Remove object's drawIndex has been made falsy")
		_called = {}
		layer:draw()
		T.has(_called, {1,3,4,5}, "Removed 2nd object and others are still drawn in order")

		-- Make sure a new object has a higher drawIndex than the others, and all get drawn.
		table.insert(objs, makeNumberedObject(6))
		layer:addObject(objs[6])
		T.ok(objs[6].drawIndex > objs[5].drawIndex, "Added new object and its index is higher than the last")

		_called = {}
		layer:draw()
		T.ok(_called[5] == 6, "New object is drawn in the correct order")

		-- Remove a couple consecutive objects and re-check draw order.
		layer:removeObject(objs[3])
		layer:removeObject(objs[4])
		T.ok(not objs[3].drawIndex and not objs[4].drawIndex, "Removed two more objects, their drawIndices were cleared")
		_called = {}
		layer:draw()
		T.has(_called, {1,5,6}, "Removed two consecutive objects from the middle, the remaining objects still drawn in order")
	end,
	function()
		local layer = Layer()
		local objs = addObjects(layer, makeObjects(1, 12))
		_called = {}
		layer:removeObject(objs[9])
		layer:removeObject(objs[8])
		layer:removeObject(objs[7])
		T.ok(true, "Removing objects in reverse order works")
		layer:draw()
		T.has(_called, {1,2,3,4,5,6,10,11,12}, "Removing added objects before they are drawn works")

		layer:removeObject(objs[10])
		layer:removeObject(objs[11])
		layer:removeObject(objs[12])
		_called = {}
		layer:draw()
		T.has(_called, {1,2,3,4,5,6}, "Removing consecutive objects at the end works")

		T.ok(not layer.dirty, "Layer is not dirty after drawing")
	end,
	function()
		-- Test with sorting.
		local objs = makeObjects(1, 4)
		local function ySort(a, b)
			if not a or not b then  return a  end
			local objA, objB = a[2], b[2]
			return objA.name < objB.name
		end
		local layer = Layer()
		layer:setSort(ySort)
		addObjects(layer, objs)
		_called = {}
		layer:removeObject(objs[1])
		layer:removeObject(objs[2])
		layer:removeObject(objs[3])
		-- Remove objects early in draw order.
		-- The sort will move the remaining object up but not change it's drawIndex.
		layer:draw()
		-- That should get sorted out in draw and let you remove the object-
		--    (which uses the object's drawIndex to find it in the layer)
		local isSuccess, errMsg = pcall(layer.removeObject, layer, objs[4])
		T.ok(isSuccess, "Removing after deleting earlier siblings and then sorting works")
		if not isSuccess then  print("", errMsg)  end
	end
}
