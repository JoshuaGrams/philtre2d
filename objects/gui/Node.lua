local base = (...):gsub('[^%.]+%.[^%.]+$', '')
local Object = require(base .. 'Object')

local Node = Object:extend()
Node.className = 'Node'

local Alloc = require(base .. 'gui.Allocation')

local DEFAULT_MODE = 'none'

local min, max = math.min, math.max
local sin, cos = math.sin, math.cos

local CARDINALS = {
	N = {0, -1}, NE = {1, -1}, E = {1, 0}, SE = {1, 1},
	S = {0, 1}, SW = {-1, 1}, W = {-1, 0}, NW = {-1, -1}, C = {0, 0},
	n = {0, -1}, ne = {1, -1}, e = {1, 0}, se = {1, 1},
	s = {0, 1}, sw = {-1, 1}, w = {-1, 0}, nw = {-1, -1}, c = {0, 0},
}

local function rotate(x, y, angle)
	local c, s = cos(angle), sin(angle)
	return c * x - s * y, s * x + c * y
end

function Node.TRANSFORM_ANCHORED_PIVOT(s) -- anchor + self from pivot * parent
	local m = s._toWorld
	local pivotX, pivotY = s.w * s.px/2, s.h * s.py/2
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
	local w2, h2 = self.w/2, self.h/2
	return lx > -w2 and lx < w2 and ly > -h2 and ly < h2
end

Node._scaleFuncs = { -- Get the new absolute scale.
	none = function(self, w, h, designW, designH, scale)
		return scale, scale
	end,
	fit = function(self, w, h, designW, designH, scale)
		local s = min(w/designW, h/designH)
		return s, s
	end,
	cover = function(self, w, h, designW, designH, scale)
		local s = max(w/designW, h/designH)
		return s, s
	end,
	stretch = function(self, w, h, designW, designH, scale)
		return w/designW, h/designH
	end,
	fill = function(self, w, h, designW, designH, scale)
		return w/self.designRect.w, h/self.designRect.h
	end
}
local scaleFuncs = Node._scaleFuncs

function Node.drawDebug(self)
	love.graphics.setColor(self.debugColor)
	local pivotPosx, pivotPosy = self.w*self.px/2, self.h*self.py/2
	local s = self.lastAlloc.scale
	love.graphics.circle('fill', pivotPosx, pivotPosy, 4*s, 8)
	love.graphics.line(-8*s, 0, 8*s, 0)
	love.graphics.line(0, -8*s, 0, 8*s)
	if self.padX ~= 0 or self.padY ~= 0 then
		local iw, ih = self.contentAlloc.w, self.contentAlloc.h
		love.graphics.rectangle('line', -iw/2, -ih/2, iw, ih)
	end
	love.graphics.rectangle('line', -self.w/2, -self.h/2, self.w, self.h)
end

function Node.init(self)
	if self.parent.allocateChild then  self.parent:allocateChild(self)  end
end

function Node.request(self)
	return self.designRect
end

function Node.allocateChild(self, child)
	-- Doesn't care what the child's request is, just allocates the full content area.

	-- Always allocate children based on -original- (unchanging) design size, so
	-- they scale correctly even after we've changed size (or padding) at runtime.
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

-- ----------  Allocation Sub-Methods  ----------
-- Node.allocate is split up into pieces so inheriting objects won't have to rewrite the whole thing.
-- Each should return true if anything actually changed.

function Node.updateScale(self, x, y, w, h, designW, designH, scale)
	if scale ~= self.lastAlloc.scale then
		local design = self.designRect
		self.pos.x, self.pos.y = design.x * scale, design.y * scale
		self.contentAlloc.scale = scale -- Also pass on scale to children.
		-- NOTE: Padding is stored in un-scaled coords, but it's effect will be scaled in updateInnerSize.
		return true
	end
end

function Node.updateOffset(self, x, y, w, h, designW, designH, scale)
	-- The offset only actually affects our transform matrices.
	local isDirty = x ~= self.lastAlloc.x or y ~= self.lastAlloc.y
	return isDirty
end

function Node.updateInnerSize(self, x, y, w, h, designW, designH, scale)
	local contentAlloc = self.contentAlloc
	local oldW, oldH = contentAlloc.w, contentAlloc.h
	local newW = max(0, self.w - self.padX*2*scale)
	local newH = max(0, self.h - self.padY*2*scale)
	contentAlloc.w, contentAlloc.h = newW, newH
	local isDirty = newW ~= oldW or newH ~= oldH
	return isDirty
end

function Node.updateSize(self, x, y, w, h, designW, designH, scale)
	local oldW, oldH = self.w, self.h
	local sx, _ = scaleFuncs[self.modeX](self, w, h, designW, designH, scale)
	local _, sy = scaleFuncs[self.modeY](self, w, h, designW, designH, scale)
	self.w, self.h = self.designRect.w*sx, self.designRect.h*sy
	self.anchorPosX, self.anchorPosY = w * self.ax/2, h * self.ay/2
	local isDirty = self.w ~= oldW or self.h ~= oldH
	return isDirty
end

function Node.allocate(self, x, y, w, h, designW, designH, scale)
	if not x then
		x, y, w, h, designW, designH, scale = self.lastAlloc:unpack()
	end

	local isDirty = false
	isDirty = self:updateScale(x, y, w, h, designW, designH, scale) or isDirty
	isDirty = self:updateOffset(x, y, w, h, designW, designH, scale) or isDirty
	isDirty = self:updateSize(x, y, w, h, designW, designH, scale) or isDirty
	isDirty = self:updateInnerSize(x, y, w, h, designW, designH, scale) or isDirty

	self.lastAlloc:pack(x, y, w, h, designW, designH, scale)

	if isDirty then
		self:updateTransform() -- So scripts get a correct transform on .allocate().
		self:allocateChildren()
	end
end

function Node.currentToDesign(self, w, h)
	local sx, sy = self.designRect.w / self.w, self.designRect.h / self.h
	if sx ~= sx then  sx = 1  end -- is NaN workaround to recover from a dimension being 0.
	if sy ~= sy then  sy = 1  end
	return w * sx, h * sy
end

-- ----------  Setter Methods (can be chained)  ----------
function Node.setSize(self, w, h, inDesignCoords)
	local design = self.designRect
	if inDesignCoords then
		if w then  design.w = w  end
		if h then  design.h = h  end
	else
		local dw, dh = self:currentToDesign(w or 0, h or 0)
		if w then  design.w = dw  end
		if h then  design.h = dh  end
	end

	local isDirty = self:updateSize(self.lastAlloc:unpack())
	if isDirty then
		self:updateInnerSize(self.lastAlloc:unpack())
		if self.tree then
			self:updateTransform()
			self:allocateChildren()
		end
	end
	return self
end

function Node.setPos(self, x, y, inDesignCoords, isRelative)
	local design = self.designRect
	local scale = self.lastAlloc.scale
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

function Node.setAngle(self, a)
	self.angle = a
	return self
end

function Node.setOffset(self, x, y, isRelative)
	local r = self.contentAlloc
	if isRelative then
		if x then  r.x = r.x + x  end
		if y then  r.y = r.y + y  end
	else
		if x then  r.x = x  end
		if y then  r.y = y  end
	end
	self:allocateChildren()
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

	self.anchorPosX = self.lastAlloc.w * self.ax/2
	self.anchorPosY = self.lastAlloc.h * self.ay/2
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
	return self
end

function Node.setPad(self, x, y)
	if x then  self.padX = x  end
	if y then  self.padY = y  end
	local isDirty = self:updateInnerSize(self.lastAlloc:unpack())
	if isDirty and self.tree then
		self:updateTransform()
		self:allocateChildren()
	end
	return self
end

function Node.setMode(self, x, y)
	if x then
		assert(scaleFuncs[x], 'Node.mode(): Invalid X scale mode "' .. tostring(x) .. '". Should be: "none", "fit", "cover", "stretch", or "fill".')
		self.modeX = x
	end
	if y then
		assert(scaleFuncs[y], 'Node.mode(): Invalid Y scale mode "' .. tostring(y) .. '". Should be: "none", "fit", "cover", "stretch", or "fill".')
		self.modeY = y
	end
	local isDirty = self:updateSize(self.lastAlloc:unpack())
	if isDirty then
		self:updateInnerSize(self.lastAlloc:unpack())
		if self.tree then
			self:updateTransform()
			self:allocateChildren()
		end
	end
	return self
end

local function isValidAnchor(a)
	if CARDINALS[a] then
		return true
	elseif type(a) == 'table' and tonumber(a[1]) and tonumber(a[2]) then
		return true
	end
end

function Node.set(self, w, h, pivot, anchor, modeX, modeY, padX, padY)
	Node.super.set(self)

	w, h = w or 100, h or w or 100
	self.padX = padX or 0 -- In design coords--remains un-scaled.
	self.padY = padY or padX or 0

	-- Must store three different sizes:
	-- 1. Current scaled size - Changes based on parent size.
	self.w, self.h = w, h
	self.designRect = {
		x = 0, y = 0,
		-- 2. Current design size - May be modified. Used to calculate our scaled size.
		w = w, h = h,
	}
	-- 3. Original (inner) design size - Never changes. Given to children to calculate their scaling.
	self.contentAlloc = Alloc(0, 0, w - self.padX*2, h - self.padY*2)

	self.lastAlloc = Alloc(0, 0, w, h) -- Need to save for when we modify things between allocations.

	pivot = pivot or 'C'
	anchor = anchor or 'C'
	assert(isValidAnchor(pivot), 'Node.set: Invalid pivot "'  .. tostring(pivot) .. '". Must be a cardinal direction string or a table: { [1]=x, [2]=y }.')
	assert(isValidAnchor(anchor), 'Node.set: Invalid anchor "'  .. tostring(anchor) .. '". Must be a cardinal direction string or a table: { [1]=x, [2]=y }.')
	self:setPivot(pivot)
	self:setAnchor(anchor)
	self:setMode(modeX or DEFAULT_MODE, modeY or modeX or DEFAULT_MODE)

	self.debugColor = { math.random()*0.8+0.4, math.random()*0.8+0.4, math.random()*0.8+0.4, 0.5 }
end

return Node
