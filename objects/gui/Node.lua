local base = (...):gsub('[^%.]+%.[^%.]+$', '')
local Object = require(base .. 'Object')

local Node = Object:extend()
Node.className = 'Node'

local Alloc = require(base .. 'gui.Allocation')

local DEFAULT_MODE = 'pixels'

local max = math.max
local sin, cos = math.sin, math.cos

local CARDINALS = {
	N = {0.5, 0}, NE = {1, 0}, E = {1, 0.5}, SE = {1, 1},
	S = {0.5, 1}, SW = {0, 1}, W = {0, 0.5}, NW = {0, 0}, C = {0.5, 0.5}
}

local xScaleFuncs = {
	pixels   = function(self, x, y, w, h, scale)  return self.xParam           end,
	units    = function(self, x, y, w, h, scale)  return self.xParam * scale   end,
	percentw = function(self, x, y, w, h, scale)  return self.xParam/100 * w   end,
	percenth = function(self, x, y, w, h, scale)  return self.xParam/100 * h   end,
	aspect   = function(self, x, y, w, h, scale)  return self.h * self.xParam  end,
	relative = function(self, x, y, w, h, scale)  return w + self.xParam       end
}
local yScaleFuncs = {
	pixels   = function(self, x, y, w, h, scale)  return self.yParam           end,
	units    = function(self, x, y, w, h, scale)  return self.yParam * scale   end,
	percentw = function(self, x, y, w, h, scale)  return self.yParam/100 * w   end,
	percenth = function(self, x, y, w, h, scale)  return self.yParam/100 * h   end,
	aspect   = function(self, x, y, w, h, scale)  return self.w / self.yParam  end,
	relative = function(self, x, y, w, h, scale)  return h + self.yParam       end
}
Node.xScaleFuncs, Node.yScaleFuncs = xScaleFuncs, yScaleFuncs
local _modeShorthands = {
	px = 'pixels', u = 'units', ['%w'] = 'percentw', ['%h'] = 'percenth', rel = 'relative', ['+'] = 'relative'
}
for abbrev,full in pairs(_modeShorthands) do
	xScaleFuncs[abbrev] = xScaleFuncs[full]
	yScaleFuncs[abbrev] = yScaleFuncs[full]
end
xScaleFuncs['%'] = xScaleFuncs['percentw']
yScaleFuncs['%'] = yScaleFuncs['percenth']
-- For setMode() error messages:
local _allModesStr = '"pixels", "units", "percentw", "percenth", "aspect", "relative", "px", "u", "%", "%w", "%h", "rel", or "+"'

Node.modeSetsDesire = { pixels = true, px = true, units = true, u = true, aspect = true }

local function rotate(x, y, angle)
	local c, s = cos(angle), sin(angle)
	return c * x - s * y, s * x + c * y
end

function Node.TRANSFORM_ANCHORED_PIVOT(s) -- anchor + self from pivot * parent
	local m = s._toWorld
	local pivotX, pivotY = s.w * s.px, s.h * s.py
	pivotX, pivotY = rotate(pivotX, pivotY, s.angle)
	local x, y = s.pos.x - pivotX, s.pos.y - pivotY
	x, y = s.anchorPosX + x, s.anchorPosY + y
	x, y = x + s.lastAlloc.x, y + s.lastAlloc.y
	m = matrix.new(x, y, s.angle, 1, 1, s.kx, s.ky, m)
	m = matrix.xM(m, s.parent._toWorld, m)
	s._toLocal = nil
end

Node.updateTransform = Node.TRANSFORM_ANCHORED_PIVOT

function Node.hitCheck(self, x, y)
	local lx, ly = self:toLocal(x, y)
	-- Inclusive on top left, exclusive on bottom right.
	return lx >= 0 and lx < self.w and ly >= 0 and ly < self.h
end

function Node.drawDebug(self)
	-- Offset things by half a pixel so it appears pixel-perfect.
	love.graphics.setColor(self.debugColor)
	local pivotX, pivotY = self.w*self.px, self.h*self.py
	local s = self.lastAlloc.scale
	love.graphics.circle('line', pivotX, pivotY, 4*s, 8)
	love.graphics.line(-6*s, 0.5, 6*s, 0.5)
	love.graphics.line(0.5, -6*s, 0.5, 6*s)
	if self.padX ~= 0 or self.padY ~= 0 then
		local iw, ih = self.contentAlloc.w, self.contentAlloc.h
		love.graphics.rectangle('line', self.padX, self.padY, iw, ih)
	end
	love.graphics.rectangle('line', 0.5, 0.5, self.w-1, self.h-1)
end

function Node.init(self)
	if self.parent.allocateChild then  self.parent:allocateChild(self)  end
end

function Node.desire(self, w, h)
	if w then  self.desiredW = w  end
	if h then  self.desiredH = h  end
	return self
end

function Node.request(self)
	return self.desiredW, self.desiredH
end

function Node.allocateChild(self, child)
	-- Doesn't care what the child's request is, just allocates the full content area.
	child:call('allocate', self.contentAlloc:unpack())
end

function Node.allocateChildren(self)
	if self.children then
		for i=1,self.children.maxn or #self.children do
			local child = self.children[i]
			if child then  self:allocateChild(child)  end
		end
	end
end

function Node.onTransformChanged(self)
	if self.tree then  self:updateTransform()  end
end

function Node.onContentAllocChanged(self)
	self:onTransformChanged()
	self:allocateChildren()
end

function Node.onSizeParamsChanged(self)
	local isDirty = self:updateSize(self.lastAlloc:unpack())
	if isDirty then  self:onContentParamsChanged(true)  end
end

function Node.onContentParamsChanged(self, isDirty)
	isDirty = self:updateContentSize(self.lastAlloc:unpack()) or isDirty
	if isDirty then  self:onContentAllocChanged()  end
end

-- ----------  Allocation Sub-Methods  ----------
-- Node.allocate is split up into pieces so inheriting objects won't have to rewrite the whole thing.
-- Each should return true if anything actually changed.

function Node.updateScale(self, x, y, w, h, scale)
	if scale ~= self.lastAlloc.scale then
		self.contentAlloc.scale = scale -- Also pass on scale to children.
		-- NOTE: Padding is stored in un-scaled coords, but it's effect will be scaled in updateContentSize.
		return true
	end
end

function Node.updateOffset(self, x, y, w, h, scale)
	-- Mark as dirty if offset changes so our transform will be updated.
	local isDirty = x ~= self.lastAlloc.x or y ~= self.lastAlloc.y
	return isDirty
end

function Node.updateContentSize(self, x, y, w, h, scale)
	local content = self.contentAlloc
	local oldX, oldY, oldW, oldH = content.x, content.y, content.w, content.h
	local newX = self._scrollX + self.padX*scale
	local newY = self._scrollY + self.padY*scale
	local newW = max(0, self.w - self.padX*2*scale)
	local newH = max(0, self.h - self.padY*2*scale)
	content.x, content.y, content.w, content.h = newX, newY, newW, newH
	local isDirty = newW ~= oldW or newH ~= oldH or oldX ~= newX or oldY ~= newY
	return isDirty
end

function Node.updateSize(self, x, y, w, h, scale)
	local oldW, oldH = self.w, self.h
	local oldAnchorX, oldAnchorY = self.anchorPosX, self.anchorPosY
	if self.modeX == 'aspect' then -- In this case, need to calc new height to use for width first.
		self.h = yScaleFuncs[self.modeY](self, x, y, w, h, scale)
		self.w = xScaleFuncs[self.modeX](self, x, y, w, h, scale)
	else
		self.w = xScaleFuncs[self.modeX](self, x, y, w, h, scale)
		self.h = yScaleFuncs[self.modeY](self, x, y, w, h, scale)
	end
	if self.modeSetsDesire[self.modeX] then  self.desiredW = self.w  end
	if self.modeSetsDesire[self.modeY] then  self.desiredH = self.h  end
	self.anchorPosX, self.anchorPosY = w * self.ax, h * self.ay
	local isDirty = self.w ~= oldW or self.h ~= oldH
	isDirty = isDirty or self.anchorPosX ~= oldAnchorX or self.anchorPosY ~= oldAnchorY
	return isDirty
end

function Node.allocate(self, x, y, w, h, scale)
	if self.lastAlloc:equals(x, y, w, h, scale) then  return  end

	local isDirty = false
	isDirty = self:updateScale(x, y, w, h, scale) or isDirty
	isDirty = self:updateOffset(x, y, w, h, scale) or isDirty
	isDirty = self:updateSize(x, y, w, h, scale) or isDirty
	isDirty = self:updateContentSize(x, y, w, h, scale) or isDirty

	self.lastAlloc:pack(x, y, w, h, scale)
	if isDirty then
		self:onContentAllocChanged()
	end
end

-- ----------  Setter Methods (can be chained)  ----------
function Node.setSize(self, w, h)
	if w then  self.xParam = w  end
	if h then  self.yParam = h  end

	self:onSizeParamsChanged()
	return self
end

function Node.setPos(self, x, y, isRelative)
	local pos = self.pos
	if isRelative then
		if x then  pos.x = pos.x + x  end
		if y then  pos.y = pos.y + y  end
	else
		if x then  pos.x = x  end
		if y then  pos.y = y  end
	end
	self:onTransformChanged()
	return self
end

function Node.setCenterPos(self, x, y)
	-- Pivots are based on top-left, so add 0.5 (subtract 0.5 less) to get the center.
	local px, py = self.w * (self.px - 0.5), self.h * (self.py - 0.5)
	px, py = rotate(px, py, self.angle)
	if x then  self.pos.x = x - self.anchorPosX + px  end
	if y then  self.pos.y = y - self.anchorPosY + py  end
	self:onTransformChanged()
	return self
end

function Node.setAngle(self, a)
	self.angle = a
	self:onTransformChanged()
	return self
end

function Node.setScroll(self, x, y, isRelative)
	if isRelative then
		if x then  self._scrollX = self._scrollX + x  end
		if y then  self._scrollY = self._scrollY + y  end
	else
		if x then  self._scrollX = x  end
		if y then  self._scrollY = y  end
	end
	self:onContentParamsChanged()
	return self
end

function Node.setAnchor(self, x, y)
	local cardinal = CARDINALS[x]
	if cardinal then
		self.ax, self.ay = cardinal[1], cardinal[2]
	elseif type(x) == 'table' and x[1] and x[2] then
		self.ax, self.ay = x[1], x[2]
	else
		if x then  self.ax = x  end
		if y then  self.ay = y  end
	end

	self.anchorPosX = self.lastAlloc.w * self.ax
	self.anchorPosY = self.lastAlloc.h * self.ay
	self:onTransformChanged()
	return self
end

function Node.setPivot(self, x, y)
	local cardinal = CARDINALS[x]
	if cardinal then
		self.px, self.py = cardinal[1], cardinal[2]
	elseif type(x) == 'table' and x[1] and x[2] then
		self.px, self.py = x[1], x[2]
	else
		if x then  self.px = x  end
		if y then  self.py = y  end
	end
	self:onTransformChanged()
	return self
end

function Node.setPad(self, x, y)
	if x then  self.padX = x  end
	if y then  self.padY = y  end
	self:onContentParamsChanged()
	return self
end

local function setMode(self, x, y)
	assert((x or self.modeX) ~= 'aspect' or (y or self.modeY) ~= 'aspect',  'Can\'t set both modes to "aspect".')
	if x then
		assert(xScaleFuncs[x], 'Invalid X mode "' .. tostring(x) .. '". Should be ' .. _allModesStr .. '.')
		self.modeX = x
	end
	if y then
		assert(yScaleFuncs[y], 'Invalid Y mode "' .. tostring(y) .. '". Should be ' .. _allModesStr .. '.')
		self.modeY = y
	end
end

function Node.setMode(self, x, y)
	setMode(self, x, y)
	self:onSizeParamsChanged()
	return self
end

function Node.setGreedy(self, isGreedy)
	self.isGreedy = isGreedy
	if self.tree and self.parent.allocateChild then  self.parent:allocateChild(self)  end
	return self
end

local function isValidAnchor(a)
	if CARDINALS[a] then
		return true
	elseif type(a) == 'table' and tonumber(a[1]) and tonumber(a[2]) then
		return true
	end
end

function Node.set(self, w, modeX, h, modeY, pivot, anchor, padX, padY)
	Node.super.set(self)
	w, h = w or 100, h or w or 100
	modeX, modeY = modeX or DEFAULT_MODE, modeY or modeX or DEFAULT_MODE
	setMode(self, modeX, modeY)
	padX, padY = padX or 0, padY or padX or 0
	self.padX, self.padY = padX, padY

	self._scrollX, self._scrollY = 0, 0
	self.contentAlloc = Alloc(padX, padY, w - padX*2, h - padY*2)
	self.lastAlloc = Alloc(0, 0, w, h) -- Need to save for when we modify things between allocations.

	pivot = pivot or 'C'
	anchor = anchor or 'C'
	assert(isValidAnchor(pivot), 'Node.set: Invalid pivot "'  .. tostring(pivot) .. '". Must be a cardinal direction string or a table: { [1]=x, [2]=y }.')
	assert(isValidAnchor(anchor), 'Node.set: Invalid anchor "'  .. tostring(anchor) .. '". Must be a cardinal direction string or a table: { [1]=x, [2]=y }.')
	self:setPivot(pivot)
	self:setAnchor(anchor)

	self.xParam, self.yParam = w, h
	self:updateSize(0, 0, w, h, 1) -- Sets self.w/h, desiredW/H, and anchorPosX/Y.

	self.debugColor = { math.random()*0.8+0.4, math.random()*0.8+0.4, math.random()*0.8+0.4, 0.5 }
end

return Node
