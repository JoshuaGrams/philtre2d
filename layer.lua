local base = (...):gsub('[^%.]+$', '')
local Class = require(base .. 'lib.base-class')
local M = require(base .. 'matrix')

local Layer = Class:extend()

function Layer.set(self)
	self.n = 0
end

Layer.clear = Layer.set

local function addFunction(self, m, fn, ...)
	self.n = self.n + 1
	self[self.n] = {m = m, fn, ...}
end
Layer.addFunction = addFunction

function Layer.addObject(self, object)
	local m = object._to_world
	addFunction(self, m, object.call, object, 'draw')
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
	local curMatrix = nil
	local curMaskObj = nil
	for i=1,#self do
		if i > self.n then
			self[i] = nil
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
