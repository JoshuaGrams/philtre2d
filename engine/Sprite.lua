
local Object = require 'engine.Object'

local Sprite = Object:extend()

Sprite.className = 'Sprite'

local origins = {
	top = 0, middle = 0.5, bottom = 1,
	left = 0, center = 0.5, right = 1
}

function Sprite.draw(self)
	love.graphics.setColor(self.color)
	love.graphics.draw(self.image, -self.ox, -self.oy)
end

function Sprite.set(self, image, x, y, angle, sx, sy, color, ox, oy, kx, ky)
	assert(image, 'Sprite() - must specify a texture file path or Image object.')
	Sprite.super.set(self, x, y, angle, sx, sy, kx, ky)
	self.name = 'Sprite'
	if type(image) == 'string' then
		image = love.graphics.newImage(image)
	elseif image.type and image:type() == 'Image' then
		image = image
	end
	self.image = image
	self.color = color or {255, 255, 255, 255}
	local w, h = image:getDimensions()
	ox = ox or 'center';  oy = oy or 'center'
	if type(ox) == 'string' then  ox = w * origins[ox]  end
	if type(oy) == 'string' then  oy = h * origins[oy]  end
	self.ox, self.oy = ox, oy
end

return Sprite
