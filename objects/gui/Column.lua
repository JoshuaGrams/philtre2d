local base = (...):gsub('[^%.]+$', '')
local Node = require(base .. 'Node')

local Column = Node:extend()
Column.className = "Column"
Column.__axis = "y"

function Column.getChildDesire(self, child)
	local desiredW, desiredH = child:request()
	if self.__axis == "y" then  return desiredH  else  return desiredW  end -- Either could be nil so can't use ternary operator.
end

function Column.allocateChild(self, child)
	if not self:getChildDesire(child) then -- We can't place it, so just allocate it our full size.
		child:call('allocate', self.contentAlloc:unpack())
	else
		self:allocateChildren() -- Columns can't just recalculate a single child, need to redo them all.
	end
end

function Column.getChildDimensionTotals(self)
	local dim1, dim2 = 0, 0
	for i=1,self.children.maxn do
		local child = self.children[i]
		if child then
			local val = self:getChildDesire(child)
			if val then
				dim1 = dim1 + (val or 0)
				if child.isGreedy then
					dim2 = dim2 + (val or 0)
				end
			end
		end
	end
	return dim1, dim2
end

function Column.countChildren(self)
	local count = 0
	for i=1,self.children.maxn do
		local child = self.children[i]
		if child and self:getChildDesire(child) then  count = count + 1  end
	end
	return count
end

function Column.allocateHomogeneous(self, x, y, w, h, scale)
	if not self.children then  return  end
	local childCount = self:countChildren()
	if childCount == 0 then  return  end

	local spacing = self.spacing * scale
	local spacingSpace = spacing * (childCount - 1)
	local availableSpace = h - spacingSpace
	local hEach = math.max(0, availableSpace / childCount)

	local dir = self.isReversed and -1 or 1
	local increment = (hEach + spacing) * dir
	local nextY = y
	if self.isReversed then  nextY = y + h + increment  end

	for i=1,self.children.maxn do
		local child = self.children[i]
		if child and self:getChildDesire(child) then
			child:call('allocate', x, nextY, w, hEach, scale)
			nextY = nextY + increment
		end
	end
end

function Column.allocateHeterogeneous(self, x, y, w, h, scale)
	if not self.children then  return  end
	local childCount = self:countChildren()
	if childCount == 0 then  return  end

	local spacing = self.spacing * scale
	local spacingSpace = spacing * (childCount - 1)
	local availableSpace = h - spacingSpace
	local totalChildH, totalGreedyChildH = self:getChildDimensionTotals()
	local squashFactor = math.min(1, availableSpace / totalChildH)
	local extraH = math.max(0, availableSpace - totalChildH)
	local greedFactor = extraH / totalGreedyChildH

	local dir = self.isReversed and -1 or 1
	local nextY = y + (self.isReversed and h or 0)

	for i=1,self.children.maxn do
		local child = self.children[i]
		if child then
			local childH = self:getChildDesire(child)
			if childH then
				local thisH = childH * squashFactor
				if child.isGreedy then  thisH = thisH + childH * greedFactor  end
				if self.isReversed then  nextY = nextY + (thisH + spacing)*dir  end
				child:call('allocate', x, nextY, w, thisH, scale)
				if not self.isReversed then  nextY = nextY + (thisH + spacing)*dir  end
			end
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

function Column.set(self, spacing, homogeneous, isReversed, w, modeX, h, modeY, pivot, anchor, padX, padY)
	Column.super.set(self, w, modeX, h, modeY, pivot, anchor, padX, padY)
	self.spacing = spacing or 0
	self.homogeneous = homogeneous or false
	self.isReversed = isReversed
end

return Column
