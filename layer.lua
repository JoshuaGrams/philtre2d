local base = (...):gsub('[^%.]+$', '')
local Class = require(base .. 'lib.base-class')
local M = require(base .. 'matrix')

local Layer = Class:extend()

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
	local i = object.drawIndex
	assert(i, "Layer.removeObject - No `drawIndex` property on object: " .. tostring(object))
	local item = self[i]
	assert(item and item[2] == object, "Layer.removeObject - Object '" .. tostring(object) .. "' is not in this layer. " .. tostring(self))

	-- Don't table.remove or object drawIndices will not match their place in the list (needed for removing other objects).
	-- Don't set to nil or it will break iteration.
	self[i] = false
	-- False elements will be removed in refreshIndices().
	self.dirty = true
	-- Leave self.n as-is so added objects won't overwrite existing ones. It will be updated in refreshIndices().
end

-- Update all objects' drawIndices to be consecutive and clean up holes from removed objects.
function Layer.refreshIndices(self)
	if self.dirty then
		for i=1,#self do
			while self[i] == false do -- May be consecutive false elements that get moved up each table.remove.
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

-- Reset to origin and apply object's to-world transform.
local function applyMaskObjectTransform(obj)
	love.graphics.push()
	love.graphics.origin()
	local m = obj._to_world
	local th, sx, sy, kx, ky = M.parameters(m)
	love.graphics.translate(m.x, m.y)
	love.graphics.rotate(th)
	love.graphics.scale(sx, sy)
	love.graphics.shear(kx, ky)
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
				local th, sx, sy, kx, ky = M.parameters(curMatrix)
				love.graphics.push()
				love.graphics.translate(curMatrix.x, curMatrix.y)
				love.graphics.rotate(th)
				love.graphics.scale(sx, sy)
				love.graphics.shear(kx, ky)
			end
			local maskObj = params[2].maskObject
			if curMaskObj ~= maskObj then
				if maskObj then
					applyMaskObjectTransform(maskObj)
					maskObj:enableMask()
					love.graphics.pop()
				elseif curMaskObj then
					applyMaskObjectTransform(curMaskObj)
					curMaskObj:disableMask()
					love.graphics.pop()
				end
				curMaskObj = maskObj
			end
			params[1](unpack(params, 2))
			if pushed then  love.graphics.pop()  end
		end
	end
end

return Layer
