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
	local children = objects or self.children
	for i=1,children.maxn or #children do
		local child = children[i]
		if child then
			child.maskObject = self
			if child.children and not child:is(Mask) then
				Mask.setMaskOnChildren(self, child.children)
			end
		end
	end
end

function Mask._updateInnerSize(self)
	self.innerW = math.max(0, self.w - self.padX*2)
	self.innerH = math.max(0, self.h - self.padY*2)
end

function Mask.init(self)
	Mask.super.init(self)
	self:setMaskOnChildren()
end

function Mask.setOffset(self, x, y)
	if self.children then
		for i=1,self.children.maxn or #self.children do
			local child = self.children[i]
			if child then  child.parentOffsetX, child.parentOffsetY = x, y  end
		end
	end
end

function Mask.set(self, stencilFunc, x, y, angle, w, h, px, py, ax, ay, resizeMode, padX, padY)
	Mask.super.set(self, x, y, angle, w, h, px, py, ax, ay, resizeMode, padX, padY)
	stencilFunc = stencilFunc or defaultStencilFunc
	self.stencilFunc = function()  stencilFunc(self)  end
end

return Mask
