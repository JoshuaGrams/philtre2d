local base = (...):gsub('[^%.]+$', '')
local Node = require(base .. 'Node')

local Mask = Node:extend()
Mask.className = "Mask"

local function defaultStencilFunc(self)
	love.graphics.rectangle("fill", -self.innerW/2, -self.innerH/2, self.innerW, self.innerH)
end

function Mask.enableMask(self)
	local mode, value = love.graphics.getStencilTest()
	value = value or 0
	value = value + 1
	love.graphics.setStencilTest("gequal", value)
	love.graphics.stencil(self.stencilFunc, "increment", nil, true)
end

function Mask.disableMask(self)
	local mode, value = love.graphics.getStencilTest()
	value = math.max(0, value - 1)
	love.graphics.stencil(self.stencilFunc, "decrement", nil, true)
	if value == 0 then
		love.graphics.setStencilTest()
	else
		love.graphics.setStencilTest("gequal", value)
	end
end

function Mask.setMaskOnChildren(self, objects)
	if not self.children then  return  end
	for i,obj in ipairs(objects or self.children) do
		obj.maskObject = self
		if obj.children then
			Mask.setMaskOnChildren(self, obj.children)
		end
	end
end

function Mask.init(self)
	Mask.super.init(self)
	self:setMaskOnChildren()
end

local function recursiveSetOffset(objects, x, y)
	for i,obj in ipairs(objects) do
		obj.parentOffsetX, obj.parentOffsetY = x, y
		if obj.children then
			recursiveSetOffset(obj.children, x, y)
		end
	end
end

function Mask.setOffset(self, x, y)
	recursiveSetOffset(self.children, x, y)
end

function Mask.set(self, stencilFunc, x, y, angle, w, h, px, py, ax, ay, resizeMode, padX, padY)
	Mask.super.set(self, x, y, angle, w, h, px, py, ax, ay, resizeMode, padX, padY)
	stencilFunc = stencilFunc or defaultStencilFunc
	self.stencilFunc = function()  stencilFunc(self)  end
end

return Mask
