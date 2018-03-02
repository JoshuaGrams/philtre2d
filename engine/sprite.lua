local T = require('engine.scene-tree')

local function draw(s)
	love.graphics.setColor(255, 255, 255)
	love.graphics.draw(s.img, 0, 0, 0, 1, 1, s.ox, s.oy)
end

local methods = { draw = draw }
local class = { __index = methods }

local origins = {
	top = 0, middle = 0.5, bottom = 1,
	left = 0, center = 0.5, right = 1
}

local function new(filename, ox, oy, x, y, angle, sx, sy, kx, ky)
	local img = love.graphics.newImage(filename)
	if img then
		local sprite = T.object(x, y, angle, sx, sy, kx, ky)
		sprite.img = img
		local w, h = img:getDimensions()
		if type(ox) == 'string' then  ox = w * origins[ox]  end
		if type(oy) == 'string' then  oy = h * origins[oy]  end
		sprite.ox, sprite.oy = ox or 0, oy or 0
		return setmetatable(sprite, class)
	end
end

return { new = new, methods = methods, class = class }
