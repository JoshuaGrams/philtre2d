local base = (...):gsub('[^%.]+$', '')
local Node = require(base .. 'Node')

local SpriteNode = Node:extend()
SpriteNode.className = 'SpriteNode'

function SpriteNode.draw(self)
	love.graphics.setBlendMode(self.blendMode)
	love.graphics.setColor(self.color)
	love.graphics.draw(self.image, 0, 0, 0, self.sx, self.sy, self.imgOX, self.imgOY)
end

function SpriteNode.updateContentSize(self, x, y, w, h, scale)
	local isDirty = SpriteNode.super.updateContentSize(self, x, y, w, h, scale)
	self.sx, self.sy = self.w / self.imgW, self.h / self.imgH
	return isDirty
end

function SpriteNode.set(self, image, color, w, modeX, h, modeY, pivot, anchor, padX, padY)
	local imgType = type(image)
	if imgType == 'string' then
		image = new.image(image)
	elseif not (imgType == 'userdata' and image.type and image:type() == 'Image') then
		error('SpriteNode() - "image" must be either a string filepath to an image or a Love Image object, you gave: "' .. tostring(image) .. '" instead.')
	end
	self.image = image
	self.imgW, self.imgH = image:getDimensions()
	self:desire(self.imgW, self.imgH)
	SpriteNode.super.set(self, w, modeX, h, modeY, pivot, anchor, padX, padY)

	self.imgOX, self.imgOY = self.imgW/2, self.imgH/2
	self.sx, self.sy = self.w / self.imgW, self.h / self.imgH
	self.blendMode = 'alpha'
	self.color = color or {1, 1, 1, 1}
end

return SpriteNode
