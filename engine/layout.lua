
----------------------------------------------------------------
-- All widgets have:

local function boxRequest(self)
	return self._req
end

local boxMethods = { request = boxRequest }
local boxClass = { __index = boxMethods }

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
-- * A dimension: names for the coordinate and size that it
--   will read and set on the objects (e.g. 'x', 'width').
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

local rowMethods = {
	request = rowRequest,
	add = addToRow,
}
local rowClass = { __index = rowMethods }

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
	Box = {new = newBox, methods = boxMethods, class = boxClass},
	Row = {new = newRow, methods = rowMethods, class = rowClass}
}
