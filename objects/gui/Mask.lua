local base = (...):gsub('[^%.]+$', '')
local Node = require(base .. 'Node')

local Mask = Node:extend()
Mask.className = "Mask"

local function defaultStencilFunc(self)
	local w, h = self.contentAlloc.w, self.contentAlloc.h
	love.graphics.rectangle("fill", -w/2, -h/2, w, h)
end

function Mask.enableMask(self)
	self:applyTransform()
	local _, value = love.graphics.getStencilTest()
	value = (value or 0) + 1
	love.graphics.setStencilTest("gequal", value)
	love.graphics.stencil(self.stencilFunc, "increment", nil, true)
	self.isEnabled = true
	self:resetTransform()
end

function Mask.disableMask(self)
	self:applyTransform()
	local _, value = love.graphics.getStencilTest()
	value = math.max(0, value - 1)
	love.graphics.stencil(self.stencilFunc, "decrement", nil, true)
	if value == 0 then
		love.graphics.setStencilTest()
	else
		love.graphics.setStencilTest("gequal", value)
	end
	self.isEnabled = false
	self:resetTransform()
end

function Mask.setMaskOnChildren(self, children, isEnabled)
	if not children then  return  end
	for i=1,children.maxn or #children do
		local child = children[i]
		if child then
			if isEnabled then                child._mask = self
			elseif child._mask == self then  child._mask = nil  end
			if child.children and not child:is(Mask) then
				self:setMaskOnChildren(child.children, isEnabled)
			end
		end
	end
end

function Mask.init(self)
	Mask.super.init(self)
	self:setMaskOnChildren(self.children, true)
end

function Mask.final(self)
	self:setMaskOnChildren(self.children, false)
end

function Mask.set(self, stencilFunc, w, h, pivot, anchor, modeX, modeY, padX, padY)
	Mask.super.set(self, w, h, pivot, anchor, modeX, modeY, padX, padY)
	stencilFunc = stencilFunc or defaultStencilFunc
	self.stencilFunc = function()  stencilFunc(self)  end
end

return Mask
