local base = (...):gsub('[^%.]+$', '')
local Node = require(base .. 'Node')

local Column = Node:extend()
Column.className = "Column"

function Column._allocateChild(self, child, x, y, w, h, scale)
	local req = child:request()
	child:call('allocate', x, y, w, h, req.w, req.h, scale)
end

function Column.allocateChild(self, child)
	-- Columns can't just recalculate a single child, need to redo them all.
	self:allocateChildren()
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

function Column.allocateHomogeneous(self, x, y, w, h, designW, designH, scale)
	if not self.children then  return  end
	local childCount = self:countChildren()
	if childCount == 0 then  return  end

	local spacing = self.spacing * scale
	local spacingSpace = spacing * (childCount - 1)
	local availableSpace = h - spacingSpace
	local hEach = math.max(0, availableSpace / childCount)

	local startY = y + h/2 * self.dir
	local increment = (hEach + spacing) * -self.dir
	local percent = math.abs(self.dir)

	for i=1,self.children.maxn do
		local child = self.children[i]
		if child then
			local thisY = startY - hEach/2 * self.dir
			self:_allocateChild(child, x, thisY, w, hEach*percent, scale)
			startY = startY + increment
		end
	end
end

function Column.allocateHeterogeneous(self, x, y, w, h, designW, designH, scale)
	if not self.children then  return  end
	local childCount = self:countChildren()
	if childCount == 0 then  return  end

	local spacing = self.spacing * scale
	local spacingSpace = spacing * (childCount - 1)
	local availableSpace = h - spacingSpace
	local totalChildH, totalGreedyChildH = self:getChildDimensionTotals("h")
	totalChildH, totalGreedyChildH = totalChildH*scale, totalGreedyChildH*scale
	local squashFactor = math.min(1, availableSpace / totalChildH)
	local extraH = math.max(0, availableSpace - totalChildH)
	local greedFactor = extraH / totalGreedyChildH

	local startY = y + h/2 * self.dir
	local percent = math.abs(self.dir)

	for i=1,self.children.maxn do
		local child = self.children[i]
		if child then
			local childH = child:request().h * scale
			local thisH = childH * squashFactor
			if child.isGreedy then  thisH = thisH + childH * greedFactor  end
			local thisY = startY - thisH/2 * self.dir
			self:_allocateChild(child, x, thisY, w, thisH*percent, scale)
			startY = startY - (thisH + spacing) * self.dir
		end
	end
end

function Column.allocateChildren(self)
	if self.homogeneous then
		self:allocateHomogeneous(self.contentAlloc:unpack())
	else
		self:allocateHeterogeneous(self.contentAlloc:unpack())
	end
end

Column.refresh = Column.allocateChildren

function Column.set(self, spacing, homogeneous, dir, w, h, pivot, anchor, modeX, modeY, padX, padY)
	Column.super.set(self, w, h, pivot, anchor, modeX, modeY, padX, padY)
	self.spacing = spacing or 0
	self.homogeneous = homogeneous or false
	self.dir = dir or -1
end

return Column
