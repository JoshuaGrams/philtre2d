local base = (...):gsub('objects%.Object$', '')
local BaseClass = require(base .. 'modules.base-class')
local matrix = require(base .. 'modules.matrix')

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
	return matrix.x(obj._to_world, x, y, w)
end

function Object.toLocal(obj, x, y, w)
	if not obj._to_local then
		obj._to_local = matrix.invert(obj._to_world)
	end
	return matrix.x(obj._to_local, x, y, w)
end

function Object.__tostring(self)
	return '(' .. self.className .. ' ' .. self.id .. '): path = ' .. tostring(self.path)
end

-- Call a function on the object and its scripts (if any)
function Object.call(self, func_name, ...)
	if self[func_name] then self[func_name](self, ...) end
	if self.scripts then
		for _,script in ipairs(self.scripts) do
			if script[func_name] then  script[func_name](self, ...)  end
		end
	end
end

-- Bottom-up: calls method on self AFTER children.
function Object.callRecursive(self, func_name, ...)
	if self.children then
		for i=1,self.children.maxn or #self.children do
			local child = self.children[i]
			if child then  child:callRecursive(func_name, ...)  end
		end
	end
	self:call(func_name, ...)
end

local function debugDraw(self)
	love.graphics.setBlendMode('alpha')
	love.graphics.setColor(1, 1, 1)
	love.graphics.rectangle('line', -5, -5, 10, 10)
	love.graphics.circle('line', 0, 0, 0.5, 4)
end

function Object.debugDraw(self, layer)
	if self.tree then
		self.tree.draw_order:addFunction(layer, self._to_world, debugDraw, self)
	end
end

function Object.setVisible(self, visible)
	if visible and not self.visible then
		self.visible = true -- Before removing or the drawOrder will skip it.
		self.tree.draw_order:showObject(self)
	elseif self.visible and not visible then
		self.tree.draw_order:removeObject(self)
		self.visible = false -- After removing or the drawOrder will skip it.
	end
end

function Object.setLayer(self, layer)
	if layer == self.layer then  return  end
	self.tree.draw_order:moveObject(self, layer)
	self.layer = layer
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
