local T = require('engine.scene-tree')

local function draw(s)
	love.graphics.setColor(s.color)
	if s.font then love.graphics.setFont(s.font) end
	love.graphics.printf(s.text, s.pos.x, s.pos.y, s.wrap_limit, s.align, s.angle, s.sx, s.sy, s.ox, s.oy, s.kx, s.ky)
end

local methods = { draw = draw }
local class = { __index = methods }

local aligns = {
	center = true,
	left = true,
	right = true,
	justify = true
}

local function new(x, y, angle, text, font, wrap_limit, align, sx, sy, ox, oy, kx, ky)
	local s = T.object(x, y, angle, sx, sy, kx, ky)
	s.color = {255, 255, 255, 255}
	s.wrap_limit = wrap_limit or 200
	s.ox, s.oy = ox or s.wrap_limit/2, oy
	s.font = font
	s.text = text
	s.align = aligns[align] and align or 'center'
	return setmetatable(s, class)
end

return { new = new, methods = methods, class = class }
