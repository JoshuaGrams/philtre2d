local T = require('engine.scene-tree')

local nodes = {}

-- easier to call on module than to keep track of actual objects
local function module_win_resized(w, h)
	for i, v in ipairs(nodes) do
		v:window_resized(w, h)
	end
end

local function window_resized(self, w, h)
	self.w, self.h = w, h
	if self.children then
		for i, v in ipairs(self.children) do
			if v.parent_resized then
				v:parent_resized(self.w, self.h, self.origw, self.origh)
			end
		end
	end
end

local function final(s)
	for i, v in ipairs(nodes) do
		if v == s then table.remove(nodes, i) end
	end
end

local methods = { window_resized = window_resized, final = final }
local class = { __index = methods }

local function new()
	local s = T.object()
	s.w, s.h = love.graphics.getDimensions()
	s.origw, s.origh = s.w, s.h
	s.ox, s.oy = 0, 0
	s = setmetatable(s, class)
	table.insert(nodes, s)
	return s
end

return { new = new, methods = methods, class = class,
		 window_resized = module_win_resized }
