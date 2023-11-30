local base = (...):gsub('[^%.]+$', '')
local Node = require(base .. 'Node')

local Column = Node:extend()
Column.className = "Column"

function Column._getChildDesire(self, child)
	local _, desiredH = child:request()
	return desiredH
end

function Column._getMainDistances(self, x, y, w, h, scale)
	return y + (self.isReversed and h or 0), h
end

function Column._getCrossDistances(self, x, y, w, h, scale)
	return x, w
end

function Column._alloc(child, mainDist, mainLen, crossDist, crossLen, scale)
	-- Column cross axis is X, main axis is Y.
	child:call('allocate', crossDist, mainDist, crossLen, mainLen, scale)
end

function Column.allocateChild(self, child)
	if not self:_getChildDesire(child) then -- We can't place it, so just allocate it our full size.
		child:call('allocate', self.contentAlloc:unpack())
	else
		self:allocateChildren() -- Columns can't just recalculate a single child, need to redo them all.
	end
end

function Column.getChildData(self)
	-- Only iterate through children once and collect everything we need.
	local childCount, sumLen, sumGreedyLen = 0, 0, 0
	local childData = {}
	for i=1,self.children.maxn do
		local child = self.children[i]
		if child then
			local len = self:_getChildDesire(child)
			if len then
				childCount = childCount + 1
				sumLen = sumLen + len
				if child.isGreedy then  sumGreedyLen = sumGreedyLen + len  end
				table.insert(childData, { child = child, len = len })
			else
				table.insert(childData, { child = child, excludedFromLayout = true })
			end
		end
	end
	return childCount, sumLen, sumGreedyLen, childData
end

function Column.allocateHomogeneous(self, x, y, w, h, scale)
	if not self.children or self.children.maxn == 0 then  return  end
	local childCount, _, _, childData = self:getChildData()
	if childCount == 0 then  return  end

	local dist, totalLen = self:_getMainDistances(x, y, w, h, scale)
	local crossDist, crossLen = self:_getCrossDistances(x, y, w, h, scale)

	local spacing = self.spacing * scale
	local spacingLen = spacing * (childCount - 1)
	local availableLen = totalLen - spacingLen
	local len = math.max(0, availableLen / childCount)
	local increment = (len + spacing) * (self.isReversed and -1 or 1)

	for i,data in ipairs(childData) do
		if data.excludedFromLayout then
			data.child:call('allocate', self.contentAlloc:unpack())
		else
			self._alloc(data.child, dist, len, crossDist, crossLen, scale)
			dist = dist + increment
		end
	end
end

function Column.allocateHeterogeneous(self, x, y, w, h, scale)
	if not self.children or self.children.maxn == 0 then  return  end
	local childCount, totalChildLen, totalGreedyChildLen, childData = self:getChildData()
	if childCount == 0 then  return  end

	local dist, totalLen = self:_getMainDistances(x, y, w, h, scale)
	local crossDist, crossLen = self:_getCrossDistances(x, y, w, h, scale)

	local spacing = self.spacing * scale
	local spacingLen = spacing * (childCount - 1)
	local availableLen = totalLen - spacingLen
	local squashFactor = math.min(1, availableLen / totalChildLen)
	local extraLen = math.max(0, availableLen - totalChildLen)
	local greedFactor = extraLen / totalGreedyChildLen

	for i,data in ipairs(childData) do
		if data.excludedFromLayout then
			data.child:call('allocate', self.contentAlloc:unpack())
		else
			local child, childLen = data.child, data.len
			local len = childLen * squashFactor
			if child.isGreedy then  len = len + childLen * greedFactor  end
			if self.isReversed then  dist = dist - (len + spacing)  end -- First child must start at far end minus its size.
			self._alloc(child, dist, len, crossDist, crossLen, scale)
			if not self.isReversed then  dist = dist + (len + spacing)  end -- First child must start at 0 and count up for the next.
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
