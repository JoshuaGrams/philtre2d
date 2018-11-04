local base = (...):gsub('[^%.]+.[^%.]+$', '')
local Object = require(base .. 'Object')

local Column = Object:extend()
Column.className = 'Layout.Column'

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
Column.add = add

local function increaseRequest(req, children)
	for _,child in ipairs(children) do
		local r = child.obj:request()
		req.w = math.max(req.w, r.w)
		req.h = req.h + r.h + 2 * child.pad
	end
end

local function request(self)
	local req = { w = 0, h = 0 }
	increaseRequest(req, self.startChildren)
	increaseRequest(req, self.endChildren)
	local n = #self.startChildren + #self.endChildren
	req.h = req.h + self.spacing * (n - 1)
	self._req = req
	return req
end
Column.request = request

local function allocateChild(child, x, y, w, h)
	local obj = child.obj
	-- Subtract padding.
	y = y + math.min(h, child.pad)
	h = math.max(0, h - 2 * child.pad)
	-- Account for extra unless child wants stretching.
	if child.extra ~= 'stretch' then
		local r = obj:request()
		local ex, ey = w - r.w, h - r.h
		ex, ey = math.max(ex, 0), math.max(ey, 0)
		y, h = y + 0.5 * ey, h - ey
	end
	obj:allocate(x, y, w, h)
end

local function allocateHomogeneousColumn(self, x, y, w, h)
	local n = #self.startChildren + #self.endChildren
	if n == 0 then return end
	local a = math.max(0, h - self.spacing * (n - 1)) / n

	local top = 0
	for _,c in ipairs(self.startChildren) do
		allocateChild(c, 0, top, w, a)
		top = math.min(h, top + a + self.spacing)
	end

	local bottom = 0
	for _,c in ipairs(self.endChildren) do
		bottom = math.min(h, bottom + a)
		allocateChild(c, 0, h - bottom, w, a)
		bottom = math.min(h, bottom + self.spacing)
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

local function allocateHeterogeneousColumn(self, x, y, w, h)
	local n = #self.startChildren + #self.endChildren
	if n == 0 then return end

	local req = request(self)
	local squashFactor
	local extra = h - req.h
	if extra >= 0 then
		extra = extra / extraCount(self)
	else
		local space = self.spacing * (n - 1)
		local allocated = math.max(0, h - space)
		local requested = req.h - space
		squashFactor = allocated / requested
	end

	local top = 0
	for _,c in ipairs(self.startChildren) do
		local r = c.obj:request()
		if squashFactor ~= nil then
			r.h = r.h * squashFactor
		elseif c.extra ~= 'none' then
			r.h = r.h + extra
		end
		local a = math.max(0, math.min(h - top, r.h))
		allocateChild(c, 0, top, w, a)
		top = math.min(h, top + a + self.spacing)
	end

	local bottom = 0
	for _,c in ipairs(self.endChildren) do
		local r = c.obj:request()
		if squashFactor ~= nil then
			r.h = r.h * squashFactor
		elseif c.extra ~= 'none' then
			r.h = r.h + extra
		end
		local a = math.max(0, math.min(h - bottom, r.h))
		bottom = math.min(h, bottom + a)
		allocateChild(c, 0, h - bottom, w, a)
		bottom = math.min(h, bottom + self.spacing)
	end
end

function Column.allocate(self, x, y, w, h)
	if self.homogeneous then
		allocateHomogeneousColumn(self, x, y, w, h)
	else
		allocateHeterogeneousColumn(self, x, y, w, h)
	end
	self.pos.x, self.pos.y = x, y
end

function Column.draw(self) end

function Column.set(self, spacing, homogeneous, children)
	Column.super.set(self)
	self.spacing = spacing or 0
	self.homogeneous = homogeneous or false
	self.startChildren, self.endChildren = {}, {}
	for _,child in ipairs(children or noChildren) do
		add(self, unpack(child))
	end
end

return Column
