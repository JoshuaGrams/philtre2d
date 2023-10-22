local base = (...):gsub('render%.layer$', '')
local Class = require(base .. 'core.base-class')
local M = require(base .. 'core.matrix')

local Layer = Class:extend()

local EMPTY = false

function Layer.__tostring(self)
	return "Layer: " .. self.id
end

function Layer.set(self)
	self.count = 0
end

Layer.clear = Layer.set

local function addFunction(self, m, fn, ...)
	self.count = self.count + 1
	self[self.count] = {m = m, fn = fn, ...}
	return self.count
end
Layer.addFunction = addFunction

function Layer.addObject(self, object)
	local m = object._toWorld
	local i = addFunction(self, m, object.call, object, 'draw')
	assert(i, "Layer.addFunction returned nil index")
	object.drawIndex = i
end

function Layer.hasObject(self, object)
	local item = self[object.drawIndex]
	return item and item[1] == object
end

function Layer.removeObject(self, object)
	if object.drawIndex == nil then return end
	local i = object.drawIndex
	local item = self[i]
	assert(item and item[1] == object, "Layer.removeObject - Object '" .. tostring(object) .. "' is not in this layer. " .. tostring(self))

	object.drawIndex = nil

	-- Don't table.remove or object drawIndices will not match their place in the list.
	-- 	(which is necessary for removing other objects).
	-- Don't set to nil or it will break the length operator.
	self[i] = EMPTY
	-- Empty elements will be removed during next draw.
	self.dirty = true
	-- Leave self.count as-is so added objects won't overwrite existing ones. It will be updated in the next draw.
end

-- Use this to avoid creating a new one each time.
local tempTransform = love.math.newTransform()

local function setMask(obj, enabled)
	local t = M.toTransform(obj._toWorld, tempTransform)
	love.graphics.push()
	love.graphics.applyTransform(t)

	if enabled then  obj:enableMask()
	else  obj:disableMask()  end

	love.graphics.pop()
end

function Layer.setSort(self, sortFn)
	self.sortFn = sortFn
end

function Layer.draw(self)
	if self.sortFn then
		self.dirty = true
		table.sort(self, self.sortFn)
	end

	local curMatrix = nil
	local curMaskObj = nil
	local isDirty, isAfterRemoved, wasSorted = self.dirty, false, self.sortFn

	for i=1,#self do
		if i > self.count then
			self[i] = nil -- Clear any extra draw items past the end.
		else
			local params = self[i]

			if isDirty then -- Remove empty elements and update subsequent drawIndices.
				while params == EMPTY do -- May be consecutive empty elements that get moved up each table.remove.
					table.remove(self, i)
					self.count = self.count - 1
					params = self[i]
					isAfterRemoved = true
				end
				if isAfterRemoved or wasSorted then
					-- For loop only evaluates `#self` once, so it will go past the end after you remove elements.
					if params == nil then  break  end -- Don't iterate past the last element.

					local object = self[i][1]
					object.drawIndex = i
				end
			end

			local pushed
			local maskObj = params[1].maskObject
			if curMaskObj ~= maskObj then -- NOTE: This code prevents masks from stacking.
				if curMaskObj then  setMask(curMaskObj, false)  end
				if maskObj then  setMask(maskObj, true)  end
				curMaskObj = maskObj
			end
			if curMatrix ~= params.m then
				curMatrix, pushed = params.m, true
				local t = M.toTransform(curMatrix, tempTransform)
				love.graphics.push()
				love.graphics.applyTransform(t)
			end
			params.fn(unpack(params))
			if pushed then  love.graphics.pop()  end
		end
	end
	-- The last object in the layer may have a mask. If so, we need to disable it.
	if curMaskObj then  setMask(curMaskObj, false)  end
	self.dirty = false
end

return Layer
