local base = (...):gsub('[^%.]+$', '')
local Node = require(base .. 'Node')

local Column = Node:extend()
Column.className = "Column"

local TEMP_ALLOC = { x = 0, y = 0, w = 0, h = 0, designW = 0, designH = 0, scale = 1 }

function Column._allocateChild(self, child, x, y, w, h, scale, forceUpdate)
	local a = TEMP_ALLOC
	local req = child:request()
	a.x, a.y, a.w, a.h, a.designW, a.designH, a.scale = x, y, w, h, req.w, req.h, scale
	child:call('allocate', TEMP_ALLOC, forceUpdate)
end

function Column.allocateChild(self, child, forceUpdate)
	-- Columns can't just recalculate a single child, need to redo them all.
	self:allocateChildren(forceUpdate)
end

function Column.getChildDimensionTotals(self, key)
	local dim1, dim2 = 0, 0
	for i=1,self.children.maxn do
		local child = self.children[i]
		if child then
			local val = child:request()[key]
			dim1 = dim1 + (val or 0)
			if child.isGreedy then
				dim2 = dim2 + (val or 0)
			end
		end
	end
	return dim1, dim2
end

function Column.countChildren(self)
	local count = 0
	for i=1,self.children.maxn do
		if self.children[i] then  count = count + 1  end
	end
	return count
end

function Column.allocateHomogeneous(self, width, height, forceUpdate)
	if not self.children then  return  end
	local childCount = self:countChildren()
	if childCount == 0 then  return  end

	local spacing = self.spacing * self._myAlloc.scale
	local spacingSpace = spacing * (childCount - 1)
	local availableSpace = height - spacingSpace
	local w = width
	local h = math.max(0, availableSpace / childCount)

	local startY = height/2 * self.dir
	local increment = (h + spacing) * -self.dir
	local x = 0
	local percent = math.abs(self.dir)

	for i=1,self.children.maxn do
		local child = self.children[i]
		if child then
			local y = startY - h/2 * self.dir
			self:_allocateChild(child, x, y, w, h*percent, self._myAlloc.scale, forceUpdate)
			startY = startY + increment
		end
	end
end

function Column.allocateHeterogeneous(self, width, height, forceUpdate)
	if not self.children then  return  end
	local childCount = self:countChildren()
	if childCount == 0 then  return  end

	local spacing = self.spacing * self._myAlloc.scale
	local spacingSpace = spacing * (childCount - 1)
	local availableSpace = height - spacingSpace
	local totalChildH, totalGreedyChildH = self:getChildDimensionTotals("h")
	local squashFactor = math.min(1, availableSpace / totalChildH)
	local extraH = math.max(0, availableSpace - totalChildH)
	local greedFactor = extraH / totalGreedyChildH

	local w = width

	local startY = height/2 * self.dir
	local x = 0
	local percent = math.abs(self.dir)

	for i=1,self.children.maxn do
		local child = self.children[i]
		if child then
			local childH = child:request().h
			local h = childH * squashFactor
			if child.isGreedy then  h = h + childH * greedFactor  end
			local y = startY - h/2 * self.dir
			self:_allocateChild(child, x, y, w, h*percent, self._myAlloc.scale, forceUpdate)
			startY = startY - (h + spacing) * self.dir
		end
	end
end

function Column.allocateChildren(self, forceUpdate)
	local w, h = self._contentAlloc.w, self._contentAlloc.h
	if self.homogeneous then
		self:allocateHomogeneous(w, h, forceUpdate)
	else
		self:allocateHeterogeneous(w, h, forceUpdate)
	end
end

Column.refresh = Column.allocateChildren

function Column.set(self, spacing, homogeneous, dir, x, y, angle, w, h, px, py, ax, ay, modeX, modeY, padX, padY)
	Column.super.set(self, x, y, angle, w, h, px, py, ax, ay, modeX, modeY, padX, padY)
	self.spacing = spacing or 0
	self.homogeneous = homogeneous or false
	self.dir = dir or -1
end

return Column
