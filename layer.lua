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

function Layer.draw(self)
	local m = nil
	for i=1,#self do
		if i > self.n then
			self[i] = nil
		else
			local fn = self[i]
			local pushed
			if m ~= fn.m then
				m, pushed = fn.m, true
				local th, sx, sy, kx, ky = M.parameters(m)
				love.graphics.push()
				love.graphics.translate(m.x, m.y)
				love.graphics.rotate(th)
				love.graphics.scale(sx, sy)
				love.graphics.shear(kx, ky)
			end
			fn[1](unpack(fn, 2))
			if pushed then love.graphics.pop() end
		end
	end
end

return Layer
