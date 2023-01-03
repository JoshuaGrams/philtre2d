local base = (...):gsub('[^%.]+$', '')
local Node = require(base .. 'Node')

local SpriteNode = Node:extend()
SpriteNode.className = 'SpriteNode'

function SpriteNode.draw(self)
	love.graphics.setBlendMode(self.blendMode)
	love.graphics.setColor(self.color)
	love.graphics.draw(self.image, 0, 0, 0, self.sx, self.sy, self.imgOX, self.imgOY)
end

function SpriteNode.updateInnerSize(self, x, y, w, h, designW, designH, scale)
	SpriteNode.super.updateInnerSize(self, x, y, w, h, designW, designH, scale)
	self.sx, self.sy = self.w / self.imgW, self.h / self.imgH
end

function SpriteNode.set(self, image, sx, sy, color, pivot, anchor, modeX, modeY)
	local imgType = type(image)
	if imgType == 'string' then
		image = new.image(image)
	elseif not (imgType == 'userdata' and image.type and image:type() == 'Image') then
		error('SpriteNode() - "image" must be either a string filepath to an image or a Love Image object, you gave: "' .. tostring(image) .. '" instead.')
	end
	self.image = image
	self.imgW, self.imgH = image:getDimensions()
	sx, sy = sx or 1, sy or 1
	local w, h = self.imgW * sx, self.imgH * sy
	SpriteNode.super.set(self, w, h, pivot, anchor, modeX, modeY)

	self.imgOX, self.imgOY = self.imgW/2, self.imgH/2
	self.sx, self.sy = self.w / self.imgW, self.h / self.imgH
	self.blendMode = 'alpha'
	self.color = color or {1, 1, 1, 1}
end

return SpriteNode
