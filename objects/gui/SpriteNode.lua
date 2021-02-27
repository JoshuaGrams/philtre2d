local base = (...):gsub('[^%.]+$', '')
local Node = require(base .. 'Node')

local SpriteNode = Node:extend()
SpriteNode.className = 'SpriteNode'

function SpriteNode.draw(self)
	love.graphics.setBlendMode(self.blendMode)
	love.graphics.setColor(self.color)
	love.graphics.draw(self.image, 0, 0, 0, self.sx, self.sy, self.imgOX, self.imgOY)
end

function SpriteNode.updateInnerSize(self)
	SpriteNode.super.updateInnerSize(self)
	self.sx, self.sy = self.w / self.imgW, self.h / self.imgH
end

function SpriteNode.set(self, image, x, y, angle, sx, sy, color, px, py, ax, ay, modeX, modeY)
	if type(image) == 'string' then
		image = new.image(image)
	elseif image.type and image:type() == 'Image' then
		image = image
	end
	self.image = image
	self.imgW, self.imgH = image:getDimensions()
	sx, sy = sx or 1, sy or 1
	local w, h = self.imgW * sx, self.imgH * sy
	SpriteNode.super.set(self, x, y, angle, w, h, px, py, ax, ay, modeX, modeY)

	self.imgOX, self.imgOY = self.imgW/2, self.imgH/2
	self.sx, self.sy = self.w / self.imgW, self.h / self.imgH
	self.blendMode = 'alpha'
	self.color = color or {1, 1, 1, 1}
end

return SpriteNode
