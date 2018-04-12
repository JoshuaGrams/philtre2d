local T = require('engine.scene-tree')
local M = require('engine.matrix')

local m = {}

local function round(x)
	local r = x % 1
	return r >= 0.5 and (x - r + 1) or (x - r)
end

local function draw(s)
	m = M.invert(s._to_world, m) -- to_local matrix
	local r, sx, sy = M.parameters(m)
	local wx, wy = T.to_world(s, 0, 0)
	wx, wy = round(wx), round(wy) -- round world position

	local fontScale = 1/math.max(sx, sy)
	-- update font if scale has changed
	if fontScale ~= s.font_scale then
		s.font_scale = fontScale
		local size = s.font_size * s.font_scale
		if s.font_filename then
			s.font = love.graphics.newFont(s.font_filename, size)
		else
			s.font = love.graphics.newFont(size)
		end
	end
	-- render at world scale and rounded world position
	love.graphics.push()
	love.graphics.scale(sx, sy)
	love.graphics.origin()
	love.graphics.translate(wx, wy)

	love.graphics.setColor(s.color)
	if s.font then love.graphics.setFont(s.font) end
	love.graphics.printf(s.text, -s.ox, -s.oy, s.wrap_limit, s.align, s.angle, 1, 1, 0, 0, s.kx, s.ky)

	love.graphics.pop()
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
	local ox, oy = s.sx, s.sy -- old sx, sy
	s.sx, s.sy = s.origsx*sx, s.origsy*sy
	update_anchor_pos(s)
	-- must also scale local pos
	s.lpos.x = s.lpos.x / ox * s.sx;  s.lpos.y = s.lpos.y / oy * s.sy
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

local function new(x, y, angle, text, font_filename, font_size, wrap_limit, align, sx, sy, ax, ay, scale_mode, ox, oy, kx, ky)
	local s = T.object(x, y, angle, sx, sy, kx, ky)
	s.color = {255, 255, 255, 255}
	s.wrap_limit = wrap_limit or 200
	s.ox, s.oy = ox or s.wrap_limit/2, oy or 0
	s.text = text
	if type(font_filename) == 'string' then
		s.font_filename = font_filename
		s.font = love.graphics.newFont(font_filename, font_size)
	else
		s.font = love.graphics.newFont(font_size)
	end
	s.font_size = font_size
	s.font_scale = 1
	s.align = aligns[align] and align or 'center'
	s.scale_mode = scale_mode or 'fit'
	s.origsx, s.origsy = s.sx, s.sy
	s.lpos = { x=x, y=y }
	s.ax = get_origin(ax, 0.5)
	s.ay = get_origin(ay, 0.5)
	return setmetatable(s, class)
end

return { new = new, methods = methods, class = class }
