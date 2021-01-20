local base = (...):gsub('[^%.]+$', '')
local Node = require(base .. 'Node')

local Column = Node:extend()
Column.className = "Column"

function Column.allocateChild(self, child, x, y, w, h, scale, forceUpdate)
	child:call(
		"parentResized",
		child.designW, child.designH,
		w, h, scale, x, y, forceUpdate
	)
end

function Column.getChildDimensionTotals(self, key1, key2)
	local dim1, dim2 = 0, 0
	for i=1,self.children.maxn do
		local child = self.children[i]
		if child then
			dim1 = dim1 + (child[key1] or child[key2] or 0)
			if child.isGreedy then
				dim2 = dim2 + (child[key1] or child[key2] or 0)
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

function Column.allocateHomogeneous(self, forceUpdate)
	if not self.children then  return  end
	local childCount = self:countChildren()
	if childCount == 0 then  return  end

	local spacingSpace = self.spacing * (childCount - 1)
	local availableSpace = self.innerH - spacingSpace
	local w = self.innerW
	local h = math.max(0, availableSpace / childCount)

	local startY = self.innerH/2 * self.align
	local increment = (h + self.spacing) * self.align
	local x = 0

	for i=1,self.children.maxn do
		local child = self.children[i]
		if child then
			local y = startY - h/2 * self.align
			self:allocateChild(child, x, y, w, h, self.scale, forceUpdate)
			startY = startY + increment
		end
	end
end

function Column.allocateHeterogeneous(self, forceUpdate)
	if not self.children then  return  end
	local childCount = self:countChildren()
	if childCount == 0 then  return  end

	local spacingSpace = self.spacing * (childCount - 1)
	local availableSpace = self.innerH - spacingSpace
	local totalChildH, totalGreedyChildH = self:getChildDimensionTotals("designH", "h")
	local squashFactor = math.min(1, availableSpace / totalChildH)
	local extraH = math.max(0, availableSpace - totalChildH)
	local greedFactor = extraH / totalGreedyChildH

	local w = self.innerW

	local startY = self.innerH/2 * self.align
	local x = 0

	for i=1,self.children.maxn do
		local child = self.children[i]
		if child then
			local childH = child.designH or child.h or 0
			local h = childH * squashFactor
			if child.isGreedy then  h = h + childH * greedFactor  end
			local y = startY - h/2 * self.align
			self:allocateChild(child, x, y, w, h, self.scale, forceUpdate)
			startY = startY - (h + self.spacing) * self.align
		end
	end
end

function Column._updateChildren(self, forceUpdate)
	if self.homogeneous then
		self:allocateHomogeneous(forceUpdate)
	else
		self:allocateHeterogeneous(forceUpdate)
	end
end

Column.refresh = Column._updateChildren

function Column.set(self, spacing, homogeneous, align, x, y, angle, w, h, px, py, ax, ay, resizeMode, padX, padY)
	Column.super.set(self, x, y, angle, w, h, px, py, ax, ay, resizeMode, padX, padY)
	self.spacing = spacing or 0
	self.homogeneous = homogeneous or false
	self.align = self.align or -1
end

return Column
