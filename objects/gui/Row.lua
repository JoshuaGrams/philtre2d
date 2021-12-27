local base = (...):gsub('[^%.]+$', '')
local Column = require(base .. 'Column')

local Row = Column:extend()
Row.className = "Row"

-- The same as Column, just swapped directions (x/y, w/h).
function Row.allocateHomogeneous(self, alloc, forceUpdate)
	if not self.children then  return  end
	local childCount = self:countChildren()
	if childCount == 0 then  return  end

	local spacing = self.spacing * self._givenRect.scale
	local spacingSpace = spacing * (childCount - 1)
	local availableSpace = alloc.w - spacingSpace
	local h = alloc.h
	local w = math.max(0, availableSpace / childCount)

	local startX = alloc.x + alloc.w/2 * self.dir
	local increment = (w + spacing) * -self.dir
	local y = alloc.y
	local percent = math.abs(self.dir)

	for i=1,self.children.maxn do
		local child = self.children[i]
		if child then
			local x = startX - w/2 * self.dir
			self:_allocateChild(child, x, y, w*percent, h, self._givenRect.scale, forceUpdate)
			startX = startX + increment
		end
	end
end

-- The same as Column, just swapped directions (x/y, w/h).
function Row.allocateHeterogeneous(self, alloc, forceUpdate)
	if not self.children then  return  end
	local childCount = self:countChildren()
	if childCount == 0 then  return  end

	local spacing = self.spacing * self._givenRect.scale
	local spacingSpace = spacing * (childCount - 1)
	local availableSpace = alloc.w - spacingSpace
	local totalChildW, totalGreedyChildW = self:getChildDimensionTotals("w")
	local squashFactor = math.min(1, availableSpace / totalChildW)
	local extraW = math.max(0, availableSpace - totalChildW)
	local greedFactor = extraW / totalGreedyChildW

	local h = alloc.h

	local startX = alloc.x + alloc.w/2 * self.dir
	local y = alloc.y
	local percent = math.abs(self.dir)

	for i=1,self.children.maxn do
		local child = self.children[i]
		if child then
			local childW = child:request().w
			local w = childW * squashFactor
			if child.isGreedy then  w = w + childW * greedFactor  end
			local x = startX - w/2 * self.dir
			self:_allocateChild(child, x, y, w*percent, h, self._givenRect.scale, forceUpdate)
			startX = startX - (w + spacing) * self.dir
		end
	end
end

return Row
