local base = (...):gsub('[^%.]+$', '')
local Column = require(base .. 'Column')

local Row = Column:extend()
Row.className = "Row"

-- The same as Column, just swapped directions (x/y, w/h).
function Row.allocateHomogeneous(self, forceUpdate)
	if not self.children then  return  end
	local childCount = self:countChildren()
	if childCount == 0 then  return  end

	local spacingSpace = self.spacing * (childCount - 1)
	local availableSpace = self.innerW - spacingSpace
	local h = self.innerH
	local w = math.max(0, availableSpace / childCount)

	local startX = self.innerW/2 * self.align
	local increment = (w + self.spacing) * -self.align
	local y = 0

	for i=1,self.children.maxn do
		local child = self.children[i]
		if child then
			local x = startX - w/2 * self.align
			self:allocateChild(child, x, y, w, h, self.scale, forceUpdate)
			startX = startX + increment
		end
	end
end

-- The same as Column, just swapped directions (x/y, w/h).
function Row.allocateHeterogeneous(self, forceUpdate)
	if not self.children then  return  end
	local childCount = self:countChildren()
	if childCount == 0 then  return  end

	local spacingSpace = self.spacing * (childCount - 1)
	local availableSpace = self.innerW - spacingSpace
	local totalChildW, totalGreedyChildW = self:getChildDimensionTotals("designW", "w")
	local squashFactor = math.min(1, availableSpace / totalChildW)
	local extraW = math.max(0, availableSpace - totalChildW)
	local greedFactor = extraW / totalGreedyChildW

	local h = self.innerH

	local startX = self.innerW/2 * self.align
	local y = 0

	for i=1,self.children.maxn do
		local child = self.children[i]
		if child then
			local childW = child.designW or child.w or 0
			local w = childW * squashFactor
			if child.isGreedy then  w = w + childW * greedFactor  end
			local x = startX - w/2 * self.align
			self:allocateChild(child, x, y, w, h, self.scale, forceUpdate)
			startX = startX - (w + self.spacing) * self.align
		end
	end
end


return Row
