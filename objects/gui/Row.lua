local base = (...):gsub('[^%.]+$', '')
local Column = require(base .. 'Column')

local Row = Column:extend()
Row.className = "Row"
Row.__axis = "x"

-- The same as Column, just swapped directions (x/y, w/h).
function Row.allocateHomogeneous(self, x, y, w, h, scale)
	if not self.children then  return  end
	local childCount = self:countChildren()
	if childCount == 0 then  return  end

	local spacing = self.spacing * scale
	local spacingSpace = spacing * (childCount - 1)
	local availableSpace = w - spacingSpace
	local wEach = math.max(0, availableSpace / childCount)

	local dir = self.isReversed and -1 or 1
	local increment = (wEach + spacing) * dir
	local nextX = x
	if self.isReversed then  nextX = x + h + increment  end

	for i=1,self.children.maxn do
		local child = self.children[i]
		if child and self:getChildDesire(child) then
			child:call('allocate', nextX, y, wEach, h, scale)
			nextX = nextX + increment
		end
	end
end

-- The same as Column, just swapped directions (x/y, w/h).
function Row.allocateHeterogeneous(self, x, y, w, h, scale)
	if not self.children then  return  end
	local childCount = self:countChildren()
	if childCount == 0 then  return  end

	local spacing = self.spacing * scale
	local spacingSpace = spacing * (childCount - 1)
	local availableSpace = w - spacingSpace
	local totalChildW, totalGreedyChildW = self:getChildDimensionTotals()
	local squashFactor = math.min(1, availableSpace / totalChildW)
	local extraW = math.max(0, availableSpace - totalChildW)
	local greedFactor = extraW / totalGreedyChildW

	local dir = self.isReversed and -1 or 1
	local nextX = x + (self.isReversed and w or 0)

	for i=1,self.children.maxn do
		local child = self.children[i]
		if child then
			local childW = self:getChildDesire(child)
			if childW then
				local thisW = childW * squashFactor
				if child.isGreedy then  thisW = thisW + childW * greedFactor  end
				if self.isReversed then  nextX = nextX + (thisW + spacing)*dir  end
				child:call('allocate', nextX, y, thisW, h, scale)
				if not self.isReversed then  nextX = nextX + (thisW + spacing)*dir  end
			end
		end
	end
end

return Row
