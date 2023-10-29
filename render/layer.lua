local base = (...):gsub('render%.layer$', '')
local Class = require(base .. 'core.base-class')

local Layer = Class:extend()

local EMPTY = false

function Layer.__tostring(self)
	return "Layer: " .. self.id
end

function Layer.set(self)
	self.count = 0
end
Layer.clear = Layer.set

function Layer.addFunction(self, fn, ...)
	self.count = self.count + 1
	local params = { draw = fn, ... }
	self[self.count] = params
end

function Layer.addObject(self, object, drawFn, arg2, ...)
	self.count = self.count + 1
	local params = {
		setup = object.applyTransform,
		teardown = object.resetTransform,
		draw = drawFn or object.call,
		obj = object,
		object, arg2 or 'draw', ...
	}
	self[self.count] = params
	object.drawIndex = self.count
end

function Layer.hasObject(self, object)
	local item = self[object.drawIndex]
	return item and item[1] == object
end

function Layer.removeObject(self, object)
	local i = object.drawIndex
	if not i then  return  end
	local params = self[i]
	assert(params and params.obj == object, "Layer.removeObject - Object '" .. tostring(object) .. "' is not in this layer. " .. tostring(self))
	object.drawIndex = nil
	self[i] = EMPTY
	-- Leave self.count as-is so added objects won't overwrite existing ones (this
	-- obj is probably in the middle somewhere). It will be updated in the next draw.
end

function Layer.setSort(self, sortFn)
	self.sortFn = sortFn
end

function Layer.enableMask(self, mask)
	mask:enableMask()
end

function Layer.disableMask(self, mask)
	mask:disableMask()
end

function Layer.draw(self)
	if self.sortFn then  table.sort(self, self.sortFn)  end
	-- Iterate and remove gaps as we go.
	local currentMask
	local j = 1
	for i=1,self.count do
		local params = self[i]
		if params == EMPTY then
			self[i] = nil
			self.count = self.count - 1
		else
			if i ~= j then -- Move i's kept value to j's position, if it's not already there.
				self[j] = params
				self[i] = nil
			end
			if params.obj then  params.obj.drawIndex = j  end -- Sorting may move objects, so we should just re-set all of their drawIndices.
			j = j + 1 -- Increment position of where we'll place the next kept value.
			local mask = params.obj and params.obj._mask
			if currentMask ~= mask then
				if currentMask then  self:disableMask(currentMask)  end
				currentMask = mask
				if currentMask then  self:enableMask(currentMask)  end
			end
			if params.setup then  params.setup(params.obj)  end
			params.draw(unpack(params))
			if params.teardown then  params.teardown(params.obj)  end
		end
	end
	if currentMask then  self:disableMask(currentMask)  end -- The last object in the layer may have a mask.
end

return Layer
