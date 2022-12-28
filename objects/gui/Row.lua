local base = (...):gsub('[^%.]+$', '')
local Column = require(base .. 'Column')

local Row = Column:extend()
Row.className = "Row"

-- The same as Column, just swapped directions (x/y, w/h).
function Row.allocateHomogeneous(self, x, y, w, h, designW, designH, scale)
	if not self.children then  return  end
	local childCount = self:countChildren()
	if childCount == 0 then  return  end

	local spacing = self.spacing * scale
	local spacingSpace = spacing * (childCount - 1)
	local availableSpace = w - spacingSpace
	local wEach = math.max(0, availableSpace / childCount)

	local startX = x + w/2 * self.dir
	local increment = (wEach + spacing) * -self.dir
	local percent = math.abs(self.dir)

	for i=1,self.children.maxn do
		local child = self.children[i]
		if child then
			local thisX = startX - wEach/2 * self.dir
			self:_allocateChild(child, thisX, y, wEach*percent, h, scale)
			startX = startX + increment
		end
	end
end

-- The same as Column, just swapped directions (x/y, w/h).
function Row.allocateHeterogeneous(self, x, y, w, h, designW, designH, scale)
	if not self.children then  return  end
	local childCount = self:countChildren()
	if childCount == 0 then  return  end

	local spacing = self.spacing * scale
	local spacingSpace = spacing * (childCount - 1)
	local availableSpace = w - spacingSpace
	local totalChildW, totalGreedyChildW = self:getChildDimensionTotals("w")
	totalChildW, totalGreedyChildW = totalChildW*scale, totalGreedyChildW*scale
	local squashFactor = math.min(1, availableSpace / totalChildW)
	local extraW = math.max(0, availableSpace - totalChildW)
	local greedFactor = extraW / totalGreedyChildW

	local startX = x + w/2 * self.dir
	local percent = math.abs(self.dir)

	for i=1,self.children.maxn do
		local child = self.children[i]
		if child then
			local childW = child:request().w * scale
			local thisW = childW * squashFactor
			if child.isGreedy then  thisW = thisW + childW * greedFactor  end
			local thisX = startX - thisW/2 * self.dir
			self:_allocateChild(child, thisX, y, thisW*percent, h, scale)
			startX = startX - (thisW + spacing) * self.dir
		end
	end
end

return Row
