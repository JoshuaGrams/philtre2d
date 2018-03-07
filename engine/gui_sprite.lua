local T = require('engine.scene-tree')

local function draw(s)
	love.graphics.setColor(255, 255, 255, 127)
	love.graphics.draw(s.img, -s.ox, -s.oy)
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
	if s.children and (s.lastw ~= s.w or s.lasth ~= s.w) then
		for i, v in ipairs(s.children) do
			if v.parent_resized then v:parent_resized(s.w, s.h, s.origw, s.origh) end
		end
	end
	s.lastw, s.lasth = s.w, s.h
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

local function hit_check(s, x, y)
	local lx, ly = T.to_local(s, x, y)
	lx, ly = lx + s.ox, ly + s.oy
	if lx > 0 and lx < s.w and ly > 0 and ly < s.h then
		return true
	end
end

local methods = { init = init, parent_resized = parent_resized, draw = draw, update = update, hit_check = hit_check }
local class = { __index = methods }

local origins = {
	top = 0, middle = 0.5, bottom = 1,
	left = 0, center = 0.5, right = 1
}

local function get_origin(ox, default)
	if type(ox) == 'string' then ox = origins[ox] end
	return ox or default
end

local function new(image, ox, oy, x, y, angle, sx, sy, ax, ay, scale_mode, kx, ky)
	local img
	if type(image) == 'string' then
		img = love.graphics.newImage(image)
	elseif image.type and image:type() == 'Image' then
		img = image
	end
	if img then
		local gui = T.object(x, y, angle, sx, sy, kx, ky)
		gui.origsx, gui.origsy = sx, sy
		gui.scale_mode = scale_mode or 'fit'
		gui.lpos = { x=x, y=y }
		gui.img = img
		gui.w, gui.h = img:getDimensions()
		gui.origw, gui.origh = gui.w, gui.h
		gui.ox = gui.w * get_origin(ox, 0)
		gui.oy = gui.h * get_origin(oy, 0)
		gui.ax = get_origin(ax, 0.5)
		gui.ay = get_origin(ay, 0.5)
		return setmetatable(gui, class)
	end
end

return { new = new, methods = methods, class = class }
