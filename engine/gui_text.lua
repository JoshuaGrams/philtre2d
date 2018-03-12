local T = require('engine.scene-tree')

local function draw(s)
	love.graphics.setColor(s.color)
	if s.font then love.graphics.setFont(s.font) end
	love.graphics.printf(s.text, -s.ox, -s.oy, s.wrap_limit, s.align, s.angle, s.sx, s.sy, 0, 0, s.kx, s.ky)
end

local scale_funcs = {
	fixed = function(neww, newh, origw, origh)
		return 1, 1
	end,
	fit = function(neww, newh, origw, origh)
		local s = math.min(neww/origw, newh/origh)
		return s, s
	end,
	zoom = function(neww, newh, origw, origh)
		local s = math.max(neww/origw, newh/origh)
		return s, s
	end,
	stretch = function(neww, newh, origw, origh)
		return neww/origw, newh/origh
	end,
}

local function update_anchor_pos(s)
	s.aposx = s.parent.w * s.ax - s.parent.ox
	s.aposy = s.parent.h * s.ay - s.parent.oy
end

local function update(s, dt)
	if s.lastx ~= s.lpos.x or s.lasty ~= s.lpos.y then
		s.pos.x, s.pos.y = s.lpos.x + s.aposx, s.lpos.y + s.aposy
	end
	s.lastx, s.lasty = s.lpos.x, s.lpos.y
end

local function parent_resized(s, neww, newh, origw, origh)
	local sx, sy = scale_funcs[s.scale_mode](neww, newh, origw, origh)
	s.sx, s.sy = s.origsx*sx, s.origsy*sy
	update_anchor_pos(s)
	s.pos.x, s.pos.y = s.lpos.x + s.aposx, s.lpos.y + s.aposy
end

local function init(s)
	update_anchor_pos(s)
	s.pos.x, s.pos.y = s.lpos.x + s.aposx, s.lpos.y + s.aposy
end


local methods = { draw = draw, init = init, update = update, parent_resized = parent_resized }
local class = { __index = methods }

local aligns = {
	center = true,
	left = true,
	right = true,
	justify = true
}

local origins = {
	top = 0, middle = 0.5, bottom = 1,
	left = 0, center = 0.5, right = 1
}

local function get_origin(ox, default)
	if type(ox) == 'string' then ox = origins[ox] end
	return ox or default
end

local function new(x, y, angle, text, font, wrap_limit, align, sx, sy, ax, ay, scale_mode, ox, oy, kx, ky)
	local s = T.object(x, y, angle, sx, sy, kx, ky)
	s.color = {255, 255, 255, 255}
	s.wrap_limit = wrap_limit or 200
	s.ox, s.oy = ox or s.wrap_limit/2, oy or 0
	s.text = text
	s.font = font
	s.align = aligns[align] and align or 'center'
	s.scale_mode = scale_mode or 'fit'
	s.origsx, s.origsy = s.sx, s.sy
	s.lpos = { x=x, y=y }
	s.ax = get_origin(ax, 0.5)
	s.ay = get_origin(ay, 0.5)
	return setmetatable(s, class)
end

return { new = new, methods = methods, class = class }
