
----------------------------------------------------------------
-- All widgets have:

local function boxRequest(s)
	return s._req
end

local function allocateBox(s, x, y, w, h)
	s.x, s.y, s.w, s.h = x, y, w, h
end

local function drawBox(s)
	love.graphics.rectangle('fill', s.x, s.y, s.w, s.h)
end

local boxClass = {
	request = boxRequest, allocate = allocateBox,
	draw = drawBox, __tostring = function() return 'Box' end
}
boxClass.__index = boxClass

local function newBox(w, h)
	return setmetatable({
		_req = { w = w, h = h},
	}, boxClass)
end

----------------------------------------------------------------
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
-- * request (size): base size of element.
--
-- * extra ('none'/'space'/'stretch'): does this element want
--   more space, and what should we do with the extra?
--
-- * padding (number): units of space on either side.

local function addToRow(self, obj, dir, extra, pad)
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
end

local function increaseRowRequest(req, children)
	local e = 0
	for _,child in ipairs(children) do
		local r = child.obj:request()
		req.w = req.w + r.w + 2 * child.pad
		req.h = math.max(req.h, r.h)
	end
end

local function rowRequest(self)
	local req = { w = 0, h = 0 }
	increaseRowRequest(req, self.startChildren)
	increaseRowRequest(req, self.endChildren)
	local n = #self.startChildren + #self.endChildren
	req.w = req.w + self.spacing * (n - 1)
	return req
end

local function allocateChild(child, x, y, w, h)
	local obj = child.obj
	-- Subtract padding.
	x = x + math.min(w, child.pad)
	w = math.max(0, w - 2 * child.pad)
	-- Account for extra unless child wants stretching.
	if child.extra ~= 'stretch' then
		local r = obj:request()
		local ex, ey = w - r.w, h - r.h
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
		allocateChild(c, x + left, y, a, h)
		left = math.min(w, left + a + self.spacing)
	end

	local right = 0
	for _,c in ipairs(self.endChildren) do
		right = math.min(w, right + a)
		allocateChild(c, x + w - right, y, a, h)
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

	local req = rowRequest(self)
	local squash
	local extra = w - req.w
	if extra >= 0 then
		extra = extra / extraCount(self)
	else
		local space = self.spacing * (n - 1)
		local allocated = math.max(0, w - space)
		local requested = req.w - space
		squash = allocated / requested
	end

	local left = 0
	for _,c in ipairs(self.startChildren) do
		local r = c.obj:request()
		if squash ~= nil then
			r.w = r.w * squash
		elseif c.extra ~= 'none' then
			r.w = r.w + extra
		end
		local a = math.max(0, math.min(w - left, r.w))
		allocateChild(c, x + left, y, a, h)
		left = math.min(w, left + a + self.spacing)
	end

	local right = 0
	for _,c in ipairs(self.endChildren) do
		local r = c.obj:request()
		if squash ~= nil then
			r.w = r.w * squash
		elseif c.extra ~= 'none' then
			r.w = r.w + extra
		end
		local a = math.max(0, math.min(w - right, r.w))
		right = math.min(w, right + a)
		allocateChild(c, x + w - right, y, a, h)
		right = math.min(w, right + self.spacing)
	end
end

local function allocateRow(self, x, y, w, h)
	if self.homogeneous then
		allocateHomogeneousRow(self, x, y, w, h)
	else
		allocateHeterogeneousRow(self, x, y, w, h)
	end
end

local function drawRow(self)
	for _,c in ipairs(self.startChildren) do
		c:draw()
	end
	for _,c in ipairs(self.endChildren) do
		c:draw()
	end
end

local rowClass = {
	request = rowRequest,  allocate = allocateRow,
	add = addToRow,  draw = drawRow
}
rowClass.__index = rowClass

local noChildren = {}

local function newRow(spacing, homogeneous, children)
	local row = setmetatable({
		spacing = spacing or 0,
		homogeneous = homogeneous or false,
		startChildren = {}, endChildren = {}
	}, rowClass)
	for _,child in ipairs(children or noChildren) do
		addToRow(row, unpack(child))
	end
	return row
end

return {
	Box = {new = newBox, class = boxClass},
	Row = {new = newRow, class = rowClass}
}
