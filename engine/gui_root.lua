local T = require('engine.scene-tree')

local function window_resized(self, w, h)
	self.w, self.h = w, h
	if self.children then
		for i, v in ipairs(self.children) do
			if v.resize then v:resize() end
		end
	end
end

local methods = { window_resized = window_resized }
local class = { __index = methods }

local function new()
	local gui = T.object()
	gui.w, gui.h = love.graphics.getDimensions()
	gui.ox, gui.oy = 0, 0
	return setmetatable(gui, class)
end

return { new = new, methods = methods, class = class }
