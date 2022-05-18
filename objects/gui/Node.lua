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
	m = matrix.new(x, y, s.angle, 1, 1, s.kx, s.ky, m)
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
	cover = function(self, w, h, designW, designH, scale)
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
	if self.tree and self.drawIndex then
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
	local newScale = alloc.scale
	local given = self._givenRect
	if newScale ~= given.scale then
		local design = self._designRect
		self.pos.x, self.pos.y = design.x * newScale, design.y * newScale
		-- NOTE: Padding is stored in un-scaled coords, but it's effect will be scaled in updateInnerSize.
		self._givenRect.scale = newScale
		self._contentRect.scale = newScale -- Also pass on scale to children.
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
-- Does nothing unless padX/Y, _designRect.w/h, or scale have changed.
function Node.updateInnerSize(self) -- Called from pad() and updateSize().
	local oldW, oldH = self._contentRect.w, self._contentRect.h
	local newW = max(0, self.w - self.padX*2*self._givenRect.scale)
	local newH = max(0, self.h - self.padY*2*self._givenRect.scale)
	local isDirty = newW ~= oldW or newH ~= oldH
	if isDirty then
		self._contentRect.w = newW
		self._contentRect.h = newH
		return true
	end
end

function Node.updateSize(self, alloc)
	local w, h, designW, designH = alloc.w, alloc.h, alloc.designW, alloc.designH
	local scale = alloc.scale
	local oldW, oldH = self.w, self.h

	local sx, _ = scaleFuncs[self.modeX](self, w, h, designW, designH, scale)
	local _, sy = scaleFuncs[self.modeY](self, w, h, designW, designH, scale)
	self.w, self.h = self._designRect.w * sx, self._designRect.h * sy
	self.anchorPosX, self.anchorPosY = w * self.ax/2, h * self.ay/2

	local isDirty = self:updateInnerSize()

	local r = self._givenRect
	r.w, r.h, r.designW, r.designH, r.scale = w, h, designW, designH, scale

	if isDirty or (self.w ~= oldW or self.h ~= oldH) then  return true  end
end

function Node.allocate(self, alloc, forceUpdate)
	alloc = alloc or self._givenRect

	local isDirty = false
	isDirty = self:updateScale(alloc) or isDirty
	isDirty = self:updateOffset(alloc) or isDirty
	isDirty = self:updateSize(alloc) or isDirty

	if isDirty or forceUpdate then
		self:updateTransform() -- So scripts get a correct transform on .allocate().
		self:allocateChildren(forceUpdate)
	end
end

function Node.currentToDesign(self, w, h)
	local sx, sy = self._designRect.w / self.w, self._designRect.h / self.h
	if sx ~= sx then  sx = 1  end -- is NaN workaround to recover from a dimension being 0.
	if sy ~= sy then  sy = 1  end
	return w * sx, h * sy
end

-- ----------  Setter Methods (can be chained)  ----------
function Node.size(self, w, h, inDesignCoords)
	local design = self._designRect
	if inDesignCoords then
		if w then  design.w = w  end
		if h then  design.h = h  end
	else
		local dw, dh = self:currentToDesign(w or 0, h or 0)
		if w then  design.w = dw  end
		if h then  design.h = dh  end
	end

	local isDirty = self:updateSize(self._givenRect)
	if isDirty and self.tree then
		self:updateTransform()
		self:allocateChildren()
	end
	return self
end

function Node.setPos(self, x, y, inDesignCoords, isRelative)
	local design = self._designRect
	local scale = self._givenRect.scale
	if not inDesignCoords then
		x = x and x / scale
		y = y and y / scale
	end
	if isRelative then
		if x then  design.x = design.x + x  end
		if y then  design.y = design.y + y  end
	else
		if x then  design.x = x  end
		if y then  design.y = y  end
	end
	self.pos.x = design.x * scale
	self.pos.y = design.y * scale
	return self
end

function Node.setCenterPos(self, x, y)
	if x then
		local ox = self.anchorPosX - self.w * self.px/2
		x = x - ox
	end
	if y then
		local oy = self.anchorPosY - self.h * self.py/2
		y = y - oy
	end
	return self:setPos(x, y)
end

function Node.angle(self, a)
	self.angle = a
	return self
end

function Node.offset(self, x, y, isRelative)
	local r = self._givenRect
	if isRelative then
		if x then  r.x = r.x + x  end
		if y then  r.y = r.y + y  end
	else
		if x then  r.x = x  end
		if y then  r.y = y  end
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
	if x then  self.padX = x  end
	if y then  self.padY = y  end
	local isDirty = self:updateInnerSize()
	if isDirty and self.tree then
		self:updateTransform()
		self:allocateChildren()
	end
	return self
end

function Node.mode(self, x, y)
	if x then
		assert(scaleFuncs[x], 'Node.mode(): Invalid X scale mode "' .. tostring(x) .. '". Should be: "none", "fit", "cover", "stretch", or "fill".')
		self.modeX = x
	end
	if y then
		assert(scaleFuncs[y], 'Node.mode(): Invalid Y scale mode "' .. tostring(y) .. '". Should be: "none", "fit", "cover", "stretch", or "fill".')
		self.modeY = y
	end
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
	modeX = modeX or DEFAULT_MODE
	modeY = modeY or modeX
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

	self.debugColor = { math.random()*0.8+0.4, math.random()*0.8+0.4, math.random()*0.8+0.4, 0.5 }
end

return Node
