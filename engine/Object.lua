
local BaseClass = require 'lib.base-class'
local matrix = require 'engine.matrix'

local Object = BaseClass:extend()

function Object.TRANSFORM_REGULAR(s) -- self * parent
	local m = s._to_world
	m = matrix.new(s.pos.x, s.pos.y, s.angle, s.sx, s.sy, s.kx, s.ky, m)
	m = matrix.xM(m, s.parent._to_world, m)
	s._to_local = nil
end

function Object.TRANSFORM_ABSOLUTE(s) -- self only
	local m = s._to_world
	m = matrix.new(s.pos.x, s.pos.y, s.angle, s.sx, s.sy, s.kx, s.ky, m)
	s._to_local = nil
end

function Object.TRANSFORM_NONE(s) -- parent only
	m = s.parent._to_world
	s._to_local = nil
end

Object.update_transform = Object.TRANSFORM_REGULAR

-- Call a function on the object and its scripts (if any)
function Object.__call(self, func_name, ...)
	--print('called "' .. tostring(func_name) .. '" on ' .. self.name)
	if self[func_name] then self[func_name](self, ...) end
	if self.script then
		for _,script in ipairs(self.script) do
			if script[func_name] then  script[func_name](self, ...)  end
		end
	end
end

function Object.call_scripts(self, func_name, ...) -- necessary?
	if self.script then
		for _,script in ipairs(self.script) do
			if script[func_name] then  script[func_name](self, ...)  end
		end
	end
end

function Object.register_draw(self, draw_order)
end

function Object.set_paused(self, paused)
	self.paused = paused
	self.call_scripts('set_paused', paused)
	if self.children then
		-- Add some 'non-invasive' callback for pausing
		-- and resuming sound effects here.
		--for i,c in pairs(self.chidren) do  c:...()  end
	end
end

function Object.set_visible(self, visible)
	self.visible = visible
	self.call_scripts('set_visible', visible)
end

function Object.draw(self)
	love.graphics.rectangle('line', -5, -5, 10, 10)
	love.graphics.points(0, 0)
end

Object.visible = true

function Object.set(self, name, x, y, angle, sx, sy, kx, ky)
	-- Properties set here will actually be on the new object itself, NOT on the __index table
	self.pos = { x = x or 0, y = y or 0 }
	self.name = name or 'new object'
	self.angle = angle or 0
	self.sx = sx or 1
	self.sy = sy or sx or 1
	self.kx = kx or 0
	self.ky = ky or 0
	self._to_world = matrix.new(
		self.pos.x, self.pos.y, self.angle,
		self.sx, self.sy, self.kx, self.ky
	)
end

return Object