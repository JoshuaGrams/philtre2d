local base = (...):gsub('objects%.Object$', '')
local BaseClass = require(base .. 'core.base-class')
local matrix = require(base .. 'core.matrix')

local Object = BaseClass:extend()
Object.className = 'Object'

Object._COLORED_TOSTRING = true

function Object.TRANSFORM_REGULAR(s) -- self * parent
	local m = s._toWorld
	m = matrix.new(s.pos.x, s.pos.y, s.angle, s.sx, s.sy, s.kx, s.ky, m)
	m = matrix.xM(m, s.parent._toWorld, m)
	s._toLocal = nil
end

function Object.TRANSFORM_ABSOLUTE(s) -- self only
	local m = s._toWorld
	m = matrix.new(s.pos.x, s.pos.y, s.angle, s.sx, s.sy, s.kx, s.ky, m)
	s._toLocal = nil
end

function Object.TRANSFORM_PASS_THROUGH(s) -- parent only
	matrix.copy(s.parent._toWorld, s._toWorld)
	s._toLocal = nil
end

Object.updateTransform = Object.TRANSFORM_REGULAR

local _tempTransform = love.math.newTransform()

function Object.applyTransform(self)
	local t = matrix.toTransform(self._toWorld, _tempTransform)
	love.graphics.push()
	love.graphics.applyTransform(t)
end

function Object.resetTransform(self)
	love.graphics.pop()
end

function Object.toWorld(obj, x, y, w)
	return matrix.x(obj._toWorld, x, y, w)
end

function Object.toLocal(obj, x, y, w)
	if not obj._toLocal then
		obj._toLocal = matrix.invert(obj._toWorld)
	end
	return matrix.x(obj._toLocal, x, y, w)
end

local _format
do
	local ANSI_ESC = string.char(27)
	local ANSI_RESET = ANSI_ESC .. "[0m"
	local BRIGHT_GREEN = ANSI_ESC .. "[92m"
	local DARK_GREY = ANSI_ESC .. "[90m"
	local DARK_GREEN = ANSI_ESC .. "[32m"
	_format = BRIGHT_GREEN..'(%s '..DARK_GREY..'%s path='..DARK_GREEN..'%s'..BRIGHT_GREEN..')'..ANSI_RESET
end

function Object.__tostring(self)
	local path = tostring(self.path)
	if path and #path > 25 then
		path = '...'..path:sub(-22)
	end
	if self._COLORED_TOSTRING then
		return _format:format(self.className, self.id:sub(-4), path)
	else
		return '(' .. self.className .. ' ' .. self.id:sub(-4) .. ' path=' .. path .. ')'
	end
end

-- Call a function on the object and its scripts (if any)
function Object.call(self, fnName, ...)
	if self[fnName] then self[fnName](self, ...) end
	if self.scripts then
		for _,script in ipairs(self.scripts) do
			if script[fnName] then  script[fnName](self, ...)  end
		end
	end
end

-- Bottom-up: calls method on self AFTER children.
function Object.callRecursive(self, fnName, ...)
	if self.children then
		for i=1,self.children.maxn or #self.children do
			local child = self.children[i]
			if child then  child:callRecursive(fnName, ...)  end
		end
	end
	self:call(fnName, ...)
end

local function debugDraw(self)
	love.graphics.setBlendMode('alpha')
	love.graphics.setColor(1, 1, 1)
	love.graphics.rectangle('line', -5, -5, 10, 10)
	love.graphics.circle('line', 0, 0, 0.5, 4)
end

function Object.debugDraw(self, layer)
	if self.tree and self.drawIndex then
		self.tree.drawOrder:addFunction(layer, self._toWorld, debugDraw, self)
	end
end

function Object.setVisible(self, visible)
	if visible and not self.visible then
		self.visible = true -- Before removing or the drawOrder will skip it.
		if self.tree then  self.tree.drawOrder:showObject(self)  end
	elseif self.visible and not visible then
		if self.tree then  self.tree.drawOrder:removeObject(self)  end
		self.visible = false -- After removing or the drawOrder will skip it.
	end
end

function Object.setLayer(self, layer)
	if layer == self.layer then  return  end
	if self.tree then  self.tree.drawOrder:moveObject(self, layer)  end
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
	self._toWorld = matrix.new(
		self.pos.x, self.pos.y, self.angle,
		self.sx, self.sy, self.kx, self.ky
	)
	self.visible = true
end

return Object
