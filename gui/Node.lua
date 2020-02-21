local base = (...):gsub('[^%.]+.[^%.]+$', '')
local Object = require(base .. 'Object')

local Node = Object:extend()
Node.className = 'Node'

local DEFAULT_RESIZE_MODE = 'none'

local sin, cos = math.sin, math.cos
local function rotateVec(x, y, phi)
	local c = cos(phi);  local s = sin(phi)
	return c * x - s * y, s * x + c * y
end

function Node.TRANSFORM_ANCHORED_PIVOT(s) -- anchor + self from pivot * parent
	local m = s._to_world
	local pivotX, pivotY = s.w * s.px/2, s.h * s.py/2
	pivotX, pivotY = rotateVec(pivotX, pivotY, s.angle)
	local x, y = s.pos.x - pivotX, s.pos.y - pivotY
	x, y = s.anchorPos.x + x, s.anchorPos.y + y
	x, y = x + s.parentOffsetX, y + s.parentOffsetY
	m = matrix.new(x, y, s.angle, 1, 1, 0, 0, m)
	m = matrix.xM(m, s.parent._to_world, m)
	s._to_local = nil
end

Node.updateTransform = Node.TRANSFORM_ANCHORED_PIVOT

function Node.hitCheck(self, x, y)
	local lx, ly = self:toLocal(x, y)
	local w2, h2 = self.w/2, self.h/2
	if lx > -w2 and lx < w2 and ly > -h2 and ly < h2 then
		return true
	end
	return false
end

Node._scaleFuncs = { -- Get the new absolute scale.
	none = function(self, originalW, originalH, newW, newH)
		return 1, 1
	end,
	fit = function(self, originalW, originalH, newW, newH)
		local s = math.min(newW/originalW, newH/originalH)
		return s, s
	end,
	zoom = function(self, originalW, originalH, newW, newH)
		local s = math.max(newW/originalW, newH/originalH)
		return s, s
	end,
	stretch = function(self, originalW, originalH, newW, newH)
		return newW/originalW, newH/originalH
	end,
	fill = function(self, originalW, originalH, newW, newH)
		return newW/self.originalW, newH/self.originalH
	end
}
local scaleFuncs = Node._scaleFuncs

function Node._onRescale(self, relScale)
	self.padX, self.padY = self.padX * relScale, self.padY * relScale
	if self.resizeModeX == 'none' then  self.w = self.w * relScale  end
	if self.resizeModeY == 'none' then  self.h = self.h * relScale  end
end

function Node._updateInnerSize(self)
	self.innerW, self.innerH = self.w - self.padX*2, self.h - self.padY*2
end

function Node._updateChildren(self, forceUpdate)
	for i,child in ipairs(self.children) do
		child:call(
			'parentResized',
			self.origInnerW, self.origInnerH,
			self.innerW, self.innerH, self.scale, nil, nil, forceUpdate
		)
	end
end

function Node.parentResized(self, originalW, originalH, newW, newH, scale, ox, oy, forceUpdate)
	if scale ~= self.scale then
		local relScale = scale / self.scale
		self.pos.x = self.pos.x * relScale -- Scale offset from anchor point.
		self.pos.y = self.pos.y * relScale
		self:_onRescale(relScale)
	end

	if ox and oy then
		self.parentOffsetX, self.parentOffsetY = ox, oy
	end

	if self.resizeModeX ~= 'none' then
		local sx, _ = scaleFuncs[self.resizeModeX](self, originalW, originalH, newW, newH)
		self.w = self.originalW * sx
	end
	if self.resizeModeY ~= 'none' then
		local _, sy = scaleFuncs[self.resizeModeY](self, originalW, originalH, newW, newH)
		self.h = self.originalH * sy
	end

	self.anchorPos.x, self.anchorPos.y = newW * self.ax/2, newH * self.ay/2

	local lastW, lastH, lastScale = self.innerW, self.innerH, self.scale
	self.scale = scale
	self:_updateInnerSize()
	local didChange = self.innerW ~= lastW or self.innerH ~= lastH or self.scale ~= lastScale
	if didChange or forceUpdate then
		self:updateTransform() -- So scripts get a correct transform on .parentResized.
		if self.children then
			self:_updateChildren(forceUpdate)
		end
	end
end

local function debugDraw(self)
	love.graphics.setColor(self.debugColor)
	local pivotPosx, pivotPosy = self.w*self.px/2, self.h*self.py/2
	local s = self.scale
	love.graphics.rectangle('line', -5*s+pivotPosx, -5*s+pivotPosy, 10*s, 10*s)
	love.graphics.circle('fill', pivotPosx, pivotPosy, 4.5*s, 4)
	love.graphics.line(-8*s, 0, 8*s, 0)
	love.graphics.line(0, -8*s, 0, 8*s)
	love.graphics.rectangle('line', -self.w*0.5, -self.h*0.5, self.w, self.h)
	love.graphics.rectangle('line', -self.w*0.5+5*s, -self.h*0.5+5*s, self.w-10*s, self.h-10*s)
end

function Node.debugDraw(self, layer)
	if self.tree then
		self.tree.draw_order:addFunction(layer, self._to_world, debugDraw, self)
	end
end

function Node.init(self)
	local p = self.parent
	if p.innerW and p.innerH and p.origInnerW and p.origInnerH then
		self:call("parentResized", p.origInnerW, p.origInnerH, p.innerW, p.innerH, p.scale or 1)
	elseif p.w and p.h and p.originalW and p.originalH then
		self:call("parentResized", p.originalW, p.originalH, p.w, p.h, p.scale or 1)
	end
end

function Node._setMode(self, key, key2, val, default)
	if not val then
		self[key], self[key2] = default, default
	elseif type(val) == 'table' then
		self[key] = val[1] or val.x
		assert(scaleFuncs[self[key]], 'Node: Invalid scale mode "' .. self[key] .. '".')
		self[key2] = val[2] or val.y
		assert(scaleFuncs[self[key2]], 'Node: Invalid scale mode "' .. self[key2] .. '".')
	else
		self[key], self[key2] = val, val
		assert(scaleFuncs[val], 'Node: Invalid scale mode "' .. val .. '".')
	end
end
local setMode = Node._setMode

function Node.set(self, x, y, angle, w, h, px, py, ax, ay, resizeMode, padX, padY)
	Node.super.set(self, x, y, angle)
	self.w, self.h = w or 100, h or 100
	self.originalW, self.originalH = self.w, self.h
	self.ax, self.ay = ax or 0, ay or 0 -- anchor
	self.px, self.py = px or 0, py or 0 -- pivot
	self.parentOffsetX, self.parentOffsetY = 0, 0 -- parent offset - for auto-arranging nodes.
	self.anchorPos = { x = 0, y = 0 }
	setMode(self, 'resizeModeX', 'resizeModeY', resizeMode, DEFAULT_RESIZE_MODE)
	self.padX, self.padY = padX or 0, padY or padX or 0
	self.innerW, self.innerH = self.w - self.padX*2, self.h - self.padY*2
	self.origInnerW, self.origInnerH = self.innerW, self.innerH
	self.debugColor = {math.random()*0.8+0.4, math.random()*0.8+0.4, math.random()*0.8+0.4, 0.15}
	self.scale = 1
end

return Node
