local base = (...):gsub('objects%.Quad$', '')
local Object = require(base .. 'objects.Object')

local Quad = Object:extend()

Quad.className = 'Quad'

local origins = {
	top = 0, middle = 0.5, bottom = 1,
	left = 0, center = 0.5, right = 1
}

function Quad.draw(self)
	love.graphics.setBlendMode(self.blendMode)
	love.graphics.setColor(self.color)
	love.graphics.draw(self.image, self.quad, -self.ox, -self.oy)
end

function Quad.request(self)
	return self._req
end

function Quad.allocate(self, x, y, w, h)
	local iw, ih = self.w, self.h
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

function Quad.set(self, image, quad, x, y, angle, sx, sy, color, ox, oy, kx, ky)
	assert(image, 'Quad() - first argument must be a texture file path or Image object.')
	assert(quad, 'Quad() - second argument must be a quad or {x, y, w, h}.')
	Quad.super.set(self, x, y, angle, sx, sy, kx, ky)
	if type(image) == 'string' then
		image = new.image(image)
	end
	self.image = image
	local t, l, w, h
	if quad.typeOf and quad:typeOf('Quad') then
		t, l, w, h = quad:getViewport()
	else
		t, l, w, h = unpack(quad)
		local iw, ih = image:getDimensions()
		quad = new.quad(t, l, w, h, iw, ih)
	end
	self.quad = quad
	self.w, self.h = w, h
	self.imgW, self.imgH = w, h
	self.name = 'Quad'
	self.blendMode = 'alpha'
	self.color = color or {1, 1, 1, 1}
	self._req = { w = w, h = h }
	ox = ox or 'center';  oy = oy or 'center'
	if type(ox) == 'string' then  ox = w * origins[ox]  end
	if type(oy) == 'string' then  oy = h * origins[oy]  end
	self.ox, self.oy = ox, oy
end

return Quad
