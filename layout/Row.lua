-- Place objects along a dimension.
--
-- A container has:
--
-- * spacing (number): units between elements (not at ends).
--
-- * homogeneous (boolean): place elements at equal intervals?
--
-- Each element within the container can have:
--
-- * request (function -> {w=#, h=#}): base size of element.
--
-- * extra ('none'/'space'/'stretch'): does this element want
--   more space, and what should we do with the extra?
--
-- * padding (number): units of space on either side.

local base = (...):gsub('[^%.]+.[^%.]+$', '')
local Object = require(base .. 'Object')

local Row = Object:extend()
Row.className = 'Layout.Row'

local noChildren = {}

local function add(self, obj, dir, extra, pad)
	dir = dir or 'start'
	local child = {
		obj = obj,
		extra = extra or 'none',
		pad = pad or 0
	}
	local list
	if dir == 'start' then list = self.startChildren
	elseif dir == 'end' then list = self.endChildren end
	table.insert(list, child)
	if not self.children then self.children = {} end
	table.insert(self.children, child.obj)
end
Row.add = add

local function increaseRequest(req, children)
	for _,child in ipairs(children) do
		local r = child.obj:request()
		req.w = req.w + r.w + 2 * child.pad
		req.h = math.max(req.h, r.h)
	end
end

local function request(self)
	local req = { w = 0, h = 0 }
	increaseRequest(req, self.startChildren)
	increaseRequest(req, self.endChildren)
	local n = #self.startChildren + #self.endChildren
	req.w = req.w + self.spacing * (n - 1)
	self._req = req
	return req
end
Row.request = request

local function allocateChild(child, x, y, w, h)
	local obj = child.obj
	-- Subtract padding.
	x = x + math.min(w, child.pad)
	w = math.max(0, w - 2 * child.pad)
	-- Account for extra unless child wants stretching.
	if child.extra ~= 'stretch' then
		local r = obj:request()
		local rw, rh = r.w, r.h
		local ex, ey = w - rw, h - rh
		ex, ey = math.max(ex, 0), math.max(ey, 0)
		x, w = x + 0.5 * ex, w - ex
	end
	obj:allocate(x, y, w, h)
end

local function allocateHomogeneousRow(self, x, y, w, h)
	local n = #self.startChildren + #self.endChildren
	if n == 0 then return end
	local a = math.max(0, w - self.spacing * (n - 1)) / n

	local left = 0
	for _,c in ipairs(self.startChildren) do
		allocateChild(c, left, 0, a, h)
		left = math.min(w, left + a + self.spacing)
	end

	local right = 0
	for _,c in ipairs(self.endChildren) do
		right = math.min(w, right + a)
		allocateChild(c, w - right, 0, a, h)
		right = math.min(w, right + self.spacing)
	end
end

local function extraCount(self)
	local e = 0
	for _,child in ipairs(self.startChildren) do
		if child.extra ~= 'none' then e = e + 1 end
	end
	for _,child in ipairs(self.endChildren) do
		if child.extra ~= 'none' then e = e + 1 end
	end
	return e
end

local function allocateHeterogeneousRow(self, x, y, w, h)
	local n = #self.startChildren + #self.endChildren
	if n == 0 then return end

	local req = request(self)
	local squashFactor
	local extra = w - req.w
	if extra >= 0 then
		extra = extra / extraCount(self)
	else
		local space = self.spacing * (n - 1)
		local allocated = math.max(0, w - space)
		local requested = req.w - space
		squashFactor = allocated / requested
	end

	local left = 0
	for _,c in ipairs(self.startChildren) do
		local r = c.obj:request()
		local rw, rh = r.w, r.h
		if squashFactor ~= nil then
			rw = rw * squashFactor
		elseif c.extra ~= 'none' then
			rw = rw + extra
		end
		local a = math.max(0, math.min(w - left, rw))
		allocateChild(c, left, 0, a, h)
		left = math.min(w, left + a + self.spacing)
	end

	local right = 0
	for _,c in ipairs(self.endChildren) do
		local r = c.obj:request()
		local rw, rh = r.w, r.h
		if squashFactor ~= nil then
			rw = rw * squashFactor
		elseif c.extra ~= 'none' then
			rw = rw + extra
		end
		local a = math.max(0, math.min(w - right, rw))
		right = math.min(w, right + a)
		allocateChild(c, w - right, 0, a, h)
		right = math.min(w, right + self.spacing)
	end
end

function Row.allocate(self, x, y, w, h)
	if self.homogeneous then
		allocateHomogeneousRow(self, x, y, w, h)
	else
		allocateHeterogeneousRow(self, x, y, w, h)
	end
	self.pos.x, self.pos.y = x, y
end

function Row.draw(self) end

function Row.set(self, spacing, homogeneous, children)
	Row.super.set(self)
	self.spacing = spacing or 0
	self.homogeneous = homogeneous or false
	self.startChildren, self.endChildren = {}, {}
	for _,child in ipairs(children or noChildren) do
		add(self, unpack(child))
	end
end

return Row
