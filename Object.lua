local base = (...):gsub('[^%.]+$', '')
local BaseClass = require(base .. 'lib.base-class')
local matrix = require(base .. 'matrix')

local Object = BaseClass:extend()

Object.className = 'Object'

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

function Object.TRANSFORM_PASS_THROUGH(s) -- parent only
	matrix.copy(s.parent._to_world, s._to_world)
	s._to_local = nil
end

Object.updateTransform = Object.TRANSFORM_REGULAR

function Object.toWorld(obj, x, y, w)
	return M.x(obj._to_world, x, y, w)
end

function Object.toLocal(obj, x, y, w)
	if not obj._to_local then
		obj._to_local = M.invert(obj._to_world)
	end
	return M.x(obj._to_local, x, y, w)
end

function Object.__tostring(self)
	return '(' .. self.className .. ' ' .. self.id .. '): path = ' .. tostring(self.path)
end

-- Call a function on the object and its scripts (if any)
function Object.call(self, func_name, ...)
	if self[func_name] then self[func_name](self, ...) end
	if self.script then
		for _,script in ipairs(self.script) do
			if script[func_name] then  script[func_name](self, ...)  end
		end
	end
end

function Object.callScripts(self, func_name, ...)
	if self.script then
		for _,script in ipairs(self.script) do
			if script[func_name] then  script[func_name](self, ...)  end
		end
	end
end

function Object.setPaused(self, paused)
	self.paused = paused
	self.callScripts('setPaused', paused)
	--if self.children then
		-- Add some 'non-invasive' callback for pausing
		-- and resuming sound effects here.
		--for i,c in pairs(self.chidren) do  c:...()  end
	--end
end

function Object.setVisible(self, visible)
	self.visible = visible
	self.callScripts('setVisible', visible)
end

function Object.draw(self)
	love.graphics.setBlendMode('alpha')
	love.graphics.setColor(1, 1, 1)
	love.graphics.rectangle('line', -5, -5, 10, 10)
	love.graphics.circle('line', 0, 0, 0.5, 4)
end

function Object.set(self, x, y, angle, sx, sy, kx, ky)
	self.name = self.className
	self.pos = { x = x or 0, y = y or 0 }
	self.angle = angle or 0
	self.sx = sx or 1
	self.sy = sy or sx or 1
	self.kx = kx or 0
	self.ky = ky or 0
	self._to_world = matrix.new(
		self.pos.x, self.pos.y, self.angle,
		self.sx, self.sy, self.kx, self.ky
	)
	self.visible = true
end

return Object
