local base = (...):gsub('%.objects%.gui%.Node$', '.')
local Object = require(base .. 'objects.Object')

local Node = Object:extend()
Node.className = 'Node'

local Rect = require(base .. 'objects.gui.Rect')

local DEFAULT_MODE = 'none'

local max = math.max
local sin, cos = math.sin, math.cos

local CARDINALS = {
	N = {0, -1}, NE = {1, -1}, E = {1, 0}, SE = {1, 1},
	S = {0, 1}, SW = {-1, 1}, W = {-1, 0}, NW = {-1, -1}, C = {0, 0}
}
for k,v in pairs(CARDINALS) do  CARDINALS[string.lower(k)] = v  end

local function rotate(x, y, angle)
	local c = cos(angle);  local s = sin(angle)
	return c * x - s * y, s * x + c * y
end

function Node.TRANSFORM_ANCHORED_PIVOT(s) -- anchor + self from pivot * parent
	local m = s._to_world
	local pivotX, pivotY = s.w * s.px/2, s.h * s.py/2
	pivotX, pivotY = rotate(pivotX, pivotY, s.angle)
	local x, y = s.pos.x - pivotX, s.pos.y - pivotY
	x, y = s.anchorPosX + x, s.anchorPosY + y
	x, y = x + s._givenRect.x, y + s._givenRect.y
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
	none = function(self, w, h, designW, designH, scale)
		return scale, scale
	end,
	fit = function(self, w, h, designW, designH, scale)
		local s = math.min(w/designW, h/designH)
		return s, s
	end,
	zoom = function(self, w, h, designW, designH, scale)
		local s = math.max(w/designW, h/designH)
		return s, s
	end,
	stretch = function(self, w, h, designW, designH, scale)
		return w/designW, h/designH
	end,
	fill = function(self, w, h, designW, designH, scale)
		return w/self._designRect.w, h/self._designRect.h
	end
}
local scaleFuncs = Node._scaleFuncs

local function debugDraw(self)
	love.graphics.setColor(self.debugColor)
	local pivotPosx, pivotPosy = self.w*self.px/2, self.h*self.py/2
	local s = self._givenRect.scale
	love.graphics.circle('fill', pivotPosx, pivotPosy, 4*s, 8)
	love.graphics.line(-8*s, 0, 8*s, 0)
	love.graphics.line(0, -8*s, 0, 8*s)
	if self.padX ~= 0 or self.padY ~= 0 then
		local iw, ih = self._contentRect.w, self._contentRect.h
		love.graphics.rectangle('line', -iw/2, -ih/2, iw, ih)
	end
	love.graphics.rectangle('line', -self.w/2, -self.h/2, self.w, self.h)
end

function Node.debugDraw(self, layer)
	if self.tree then
		self.tree.draw_order:addFunction(layer, self._to_world, debugDraw, self)
	end
end

function Node.init(self)
	if self.parent.allocateChild then  self.parent:allocateChild(self)  end
end

function Node.request(self)
	return self._designRect
end

function Node.allocateChild(self, child, forceUpdate)
	-- Doesn't care what the child's request is, just allocates the full content area.
	child:call('allocate', self._contentRect, forceUpdate)
end

function Node.allocateChildren(self, forceUpdate)
	self:updateTransform() -- So scripts get a correct transform on .allocate().
	if self.children then
		for i=1,self.children.maxn or #self.children do
			local child = self.children[i]
			if child then  self:allocateChild(child, forceUpdate)  end
		end
	end
end

-- ----------  Allocation Sub-Methods  ----------
-- Node.allocate is split up into pieces so inheriting objects won't have to rewrite the whole thing.

-- 1. Set new values.
-- 2. Store allocation values.
-- 3. Return true if dirty (if anything actually changed).
function Node.updateScale(self, alloc)
	local scale = alloc.scale
	local relScale = scale / self._givenRect.scale
	if relScale ~= 1 then
		self.pos.x, self.pos.y = self.pos.x * relScale, self.pos.y * relScale -- Scale offset from anchor point.
		-- NOTE: Padding is stored in un-scaled coords, but it's effect will be scaled.

		self._givenRect.scale = scale
		self._contentRect.scale = scale -- Also pass on scale to children.
		return true
	end
end

function Node.updateOffset(self, alloc)
	local x, y = alloc.x, alloc.y
	local isDirty = x ~= self._givenRect.x or y ~= self._givenRect.y
	self._givenRect.x, self._givenRect.y = x, y
	return isDirty
end

-- Requires self.w/h to be already updated.
-- Does nothing unless padX/Y, _request.w/h, or scale have changed.
function Node.updateInnerSize(self) -- Called from pad() and updateSize().
	self._contentRect.w = max(0, self.w - self.padX*2*self._givenRect.scale)
	self._contentRect.h = max(0, self.h - self.padY*2*self._givenRect.scale)
end

function Node.updateSize(self, alloc)
	local w, h, designW, designH = alloc.w, alloc.h, alloc.designW, alloc.designH
	local scale = alloc.scale
	local oldW, oldH = self.w, self.h

	local sx, _ = scaleFuncs[self.modeX](self, w, h, designW, designH, scale)
	local _, sy = scaleFuncs[self.modeY](self, w, h, designW, designH, scale)
	self.w, self.h = self._designRect.w * sx, self._designRect.h * sy
	self.anchorPosX, self.anchorPosY = w * self.ax/2, h * self.ay/2

	self:updateInnerSize()

	local ma = self._givenRect
	ma.w, ma.h, ma.designW, ma.designH, ma.scale = w, h, designW, designH, scale

	if self.w ~= oldW or self.h ~= oldH then  return true  end
end

function Node.allocate(self, alloc, forceUpdate)
	alloc = alloc or self._givenRect

	local isDirty = false
	isDirty = self:updateScale(alloc) or isDirty
	isDirty = self:updateOffset(alloc) or isDirty
	isDirty = self:updateSize(alloc) or isDirty
	if isDirty or forceUpdate then
		self:allocateChildren(forceUpdate)
	end
end

function Node.currentToDesign(self, w, h)
	local sx, sy = self._designRect.w / self.w, self._designRect.h / self.h
	if sx ~= sx then  sx = 1  end -- is NaN workaround to recover from a dimension being 0.
	if sy ~= sy then  sy = 1  end
	return w * sx, h * sy
end

-- ----------  Setter Methods  ----------
-- Can be chained together.
function Node.size(self, w, h, inDesignCoords) -- Modifies the "design" w/h of the node.
	local req = self._designRect
	if inDesignCoords then
		if w then  req.w = w  end
		if h then  req.h = h  end
	else
		local _w, _h = self:currentToDesign(w or 0, h or 0)
		if w then  req.w = _w  end
		if h then  req.h = _h  end
	end

	local dirty = self:updateSize(self._givenRect)
	if dirty and self.tree then  self:allocateChildren()  end
	return self
end

function Node.angle(self, a)
	self.angle = a
	return self
end

function Node.offset(self, x, y, isRelative)
	local ma = self._givenRect
	if isRelative then
		ma.x, ma.y = x and ma.x + x or ma.x, y and ma.y + y or ma.y
	else
		ma.x, ma.y = x or 0, y or 0
	end
	return self
end

function Node.anchor(self, x, y)
	local cardinal = CARDINALS[x]
	if cardinal then
		self.ax, self.ay = cardinal[1], cardinal[2]
	elseif type(x) == "table" and x[1] and x[2] then
		self.ax, self.ay = x[1], x[2]
	else
		if x then  self.ax = x  end
		if y then  self.ay = y  end
	end

	self.anchorPosX = self._givenRect.w * self.ax/2
	self.anchorPosY = self._givenRect.h * self.ay/2
	return self
end

function Node.pivot(self, x, y)
	local cardinal = CARDINALS[x]
	if cardinal then
		self.px, self.py = cardinal[1], cardinal[2]
	elseif type(x) == "table" and x[1] and x[2] then
		self.px, self.py = x[1], x[2]
	else
		if x then  self.px = x  end
		if y then  self.py = y  end
	end
	return self
end

function Node.pad(self, x, y)
	self.padX, self.padY = x or 0, y or x or 0
	self:updateInnerSize()
	return self
end

function Node.mode(self, x, y)
	self.modeX, self.modeY = x or DEFAULT_MODE, y or x or DEFAULT_MODE
	assert(scaleFuncs[self.modeX], 'Node: Invalid scale mode "' .. self.modeX .. '".')
	assert(scaleFuncs[self.modeY], 'Node: Invalid scale mode "' .. self.modeY .. '".')
	if self.parent then  self:updateSize(self._givenRect)  end
	return self
end

local function isValidAnchor(a)
	if CARDINALS[a] then
		return true
	elseif type(a) == "table" and tonumber(a[1]) and tonumber(a[2]) then
		return true
	end
end

function Node.set(self, w, h, pivot, anchor, modeX, modeY, padX, padY)
	Node.super.set(self)
	pivot = pivot or "C"
	anchor = anchor or "C"
	assert(isValidAnchor(pivot), 'Node.set: Invalid pivot "'  .. tostring(pivot) .. '". Must be a cardinal direction string or a table: { [1]=x, [2]=y }.')
	assert(isValidAnchor(anchor), 'Node.set: Invalid anchor "'  .. tostring(anchor) .. '". Must be a cardinal direction string or a table: { [1]=x, [2]=y }.')
	self.w = w or 100
	self.h = h or 100
	self.padX = padX or 0
	self.padY = padY or padX or 0 -- In "design" coords--it remains un-scaled.
	local contW, contH = self.w - self.padX*2, self.h - self.padY*2

	self._designRect = Rect(0, 0, self.w, self.h) -- The space we're designed to use.
	self._givenRect = Rect(0, 0, self.w, self.h) -- The space we're given by our parent.
	self._contentRect = Rect(0, 0, contW, contH) -- The space we give to our children.

	self:pivot(pivot)
	self:anchor(anchor)
	self:mode(modeX, modeY)
	self.debugColor = { math.random()*0.8+0.4, math.random()*0.8+0.4, math.random()*0.8+0.4, 0.15 }
end

return Node
