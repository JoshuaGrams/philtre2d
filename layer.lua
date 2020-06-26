local base = (...):gsub('[^%.]+$', '')
local Class = require(base .. 'lib.base-class')
local M = require(base .. 'matrix')

local Layer = Class:extend()

local EMPTY = false

function Layer.__tostring(self)
	return "Layer: " .. self.id
end

function Layer.set(self)
	self.n = 0
end

Layer.clear = Layer.set

local function addFunction(self, m, fn, ...)
	self.n = self.n + 1
	self[self.n] = {m = m, fn, ...}
	return self.n
end
Layer.addFunction = addFunction

-- TODO?: addFunctionAtIndex()? - Add new/moved objects after their parent?

function Layer.addObject(self, object)
	local m = object._to_world
	local i = addFunction(self, m, object.call, object, 'draw')
	assert(i, "Layer.addFunction returned nil index")
	object.drawIndex = i
end

function Layer.hasObject(self, object)
	local item = self[object.drawIndex]
	return item and item[2] == object
end

function Layer.removeObject(self, object)
	if object.drawIndex == nil then return end
	local i = object.drawIndex
	local item = self[i]
	assert(item and item[2] == object, "Layer.removeObject - Object '" .. tostring(object) .. "' is not in this layer. " .. tostring(self))

	object.drawIndex = nil

	-- Don't table.remove or object drawIndices will not match their place in the list (needed for removing other objects).
	-- Don't set to nil or it will break iteration/table-length operator.
	self[i] = EMPTY
	-- Empty elements will be removed in refreshIndices() before next draw.
	self.dirty = true
	-- Leave self.n as-is so added objects won't overwrite existing ones. It will be updated in refreshIndices().
end

-- Update all objects' drawIndices to be consecutive and clean up holes from removed objects.
function Layer.refreshIndices(self)
	if self.dirty then
		for i=1,#self do
			while self[i] == EMPTY do -- May be consecutive empty elements that get moved up each table.remove.
				table.remove(self, i)
				self.n = self.n - 1
			end
			-- For loop only evaluates `#self` once, so it will go past the end after you remove elements.
			if self[i] == nil then  break  end -- Don't iterate past the last element.

			local object = self[i][2]
			object.drawIndex = i
		end
	end
end

-- Use this to avoid creating a new one each time.
local tempTransform = love.math.newTransform()

-- Reset to origin and apply object's to-world transform.
local function applyMaskObjectTransform(obj)
	love.graphics.push()
	local t = M.toTransform(obj._to_world, tempTransform)
	love.graphics.replaceTransform(t)
end

function Layer.draw(self)
	self:refreshIndices() -- Only runs if dirty.
	local curMatrix = nil
	local curMaskObj = nil
	for i=1,#self do
		if i > self.n then
			self[i] = nil -- Clear any extra draw items past the end.
		else
			local params = self[i]
			local pushed
			if curMatrix ~= params.m then
				curMatrix, pushed = params.m, true
				local t = M.toTransform(curMatrix, tempTransform)
				love.graphics.push()
				love.graphics.applyTransform(t)
			end
			local maskObj = params[2].maskObject
			if curMaskObj ~= maskObj then
				if curMaskObj then -- There may already be a mask applied - disable it.
					applyMaskObjectTransform(curMaskObj)
					curMaskObj:disableMask()
					love.graphics.pop()
				end
				if maskObj then
					applyMaskObjectTransform(maskObj)
					maskObj:enableMask()
					love.graphics.pop()
				end
				curMaskObj = maskObj
			end
			params[1](unpack(params, 2))
			if pushed then  love.graphics.pop()  end
		end
	end
	-- The last object in the layer may have a mask. If so, we need to disable it.
	if curMaskObj then
		applyMaskObjectTransform(curMaskObj)
		curMaskObj:disableMask()
		love.graphics.pop()
	end
end

return Layer
