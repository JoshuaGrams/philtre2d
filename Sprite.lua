local base = (...):gsub('[^%.]+$', '')
local Object = require(base .. 'Object')

local Sprite = Object:extend()

Sprite.className = 'Sprite'

local origins = {
	top = 0, middle = 0.5, bottom = 1,
	left = 0, center = 0.5, right = 1
}

function Sprite.draw(self)
	love.graphics.setBlendMode(self.blendMode)
	love.graphics.setColor(self.color)
	love.graphics.draw(self.image, -self.ox, -self.oy)
end

function Sprite.request(self)
	return self._req
end

function Sprite.allocate(self, x, y, w, h)
	local iw, ih = self.image:getDimensions()
	local c, s = math.cos(self.angle), math.sin(self.angle)
	local ac, as = math.abs(c), math.abs(s)

	-- Choose aspect ratio.
	local aw, ah
	if self.keepAspect then  -- Use image dimensions.
		aw, ah = iw, ih
	else  -- Interpolate from (w, h) to (h, w).
		aw, ah = w + (h - w) * as, h + (w - h) * as
	end
	-- Rotate box and scale it to fit.
	local rw, rh = aw * ac + ah * as, aw * as + ah * ac
	local scale = math.min(w / rw, h / rh)
	aw, ah = aw * scale, ah * scale
	-- Compute image scale.
	self.sx, self.sy = aw / iw, ah / ih

	local ox = (self.ox - iw/2) * self.sx
	local oy = (self.oy - ih/2) * self.sy
	self.pos.x = x + w/2 + ox * c - oy * s
	self.pos.y = y + h/2 + ox * s + oy * c
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
	self.blendMode = 'alpha'
	self.color = color or {255, 255, 255, 255}
	local w, h = image:getDimensions()
	self._req = { w = w, h = h }
	ox = ox or 'center';  oy = oy or 'center'
	if type(ox) == 'string' then  ox = w * origins[ox]  end
	if type(oy) == 'string' then  oy = h * origins[oy]  end
	self.ox, self.oy = ox, oy
end

return Sprite
