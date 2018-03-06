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

local function resize(s, neww, newh, origw, origh)
	--if origw and origh then
		local sx, sy = scale_funcs[s.scale_mode](neww, newh, origw, origh)
		s.sx, s.sy = s.origsx*sx, s.origsy*sy
	--end
	s.pos.x = s.lpos.x + neww*s.ax - s.parent.ox
	s.pos.y = s.lpos.y + newh*s.ay - s.parent.oy
	--if s.children then
	--	for i, v in ipairs(s.children) do
	--		if v.resize then v:resize(s.w, s.h) end
	--	end
	--end
end

local function init(s)
	s.pos.x = s.lpos.x + s.parent.w*s.ax - s.parent.ox
	s.pos.y = s.lpos.y + s.parent.h*s.ay - s.parent.oy
end

local methods = { init = init, resize = resize, draw = draw }
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
		gui.ox = gui.w * get_origin(ox, 0)
		gui.oy = gui.h * get_origin(oy, 0)
		gui.ax = get_origin(ax, 0.5)
		gui.ay = get_origin(ay, 0.5)
		return setmetatable(gui, class)
	end
end

return { new = new, methods = methods, class = class }
