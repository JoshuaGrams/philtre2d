local base = (...):gsub('[^%.]+$', '')
local Node = require(base .. 'Node')

local Row = Node:extend()
Row.className = "Row"

local noChildren = {}

local function addChild(self, obj, dir, isGreedy, index)
	dir = dir or 'start'
	local child = {
		obj = obj,
		isGreedy = isGreedy
	}
	local list
	if dir == 'start' then  list = self.startChildren
	elseif dir == 'end' then  list = self.endChildren  end
	index = math.min(#list + 1, math.max(0, index or #list + 1))
	table.insert(list, index, child)
	self.rowChildren[obj] = list
end

local function removeChild(self, obj)
	self.rowChildren[obj] = nil
	for i,child in ipairs(self.startChildren) do
		if child.obj == obj then
			table.remove(self.startChildren, i)
			return
		end
	end
	for i,child in ipairs(self.endChildren) do
		if child.obj == obj then
			table.remove(self.endChildren, i)
			return
		end
	end
end

local function iterateOverChildren(self, func, val)
	for i,child in ipairs(self.startChildren) do
		val = func(child, val) or val
	end
	for i,child in ipairs(self.endChildren) do
		val = func(child, val) or val
	end
	return val
end

local function _countIfGreedy(child, val)
	if child.isGreedy then  return val + 1  end
end

local function getGreedyChildrenCount(self)
	return iterateOverChildren(self, _countIfGreedy, 0)
end

local function _sumWidths(child, val)
	return val + child.obj.designW
end

local function getTotalChildrenWidth(self)
	return iterateOverChildren(self, _sumWidths, 0)
end

local function _sumGreedyWidths(child, val)
	if child.isGreedy then  return val + child.obj.designW  end
end

local function getTotalGreedyChildrenWidth(self)
	return iterateOverChildren(self, _sumGreedyWidths, 0)
end

local function allocateChild(self, child, x, y, w, h, forceUpdate)
	if not child.designW or not child.designH then
		child.designW, child.designH = child.obj.designW, child.obj.designH
	end
	child.obj:call(
		"parentResized",
		child.designW, child.designH,
		w, h, self.scale, x, y, forceUpdate
	)
end

local function allocateHomogeneousRow(self, forceUpdate)
	local h = self.innerH
	local y = 0

	local childCount = #self.startChildren + #self.endChildren
	if childCount == 0 then  return  end

	local spacingSpace = self.spacing * (childCount - 1)
	local w = math.max(0, (self.innerW - spacingSpace) / childCount)

	local leftEdgeX = -self.innerW / 2 -- No spacing at ends, only in between.
	for _,child in ipairs(self.startChildren) do
		local x = leftEdgeX + w / 2
		allocateChild(self, child, x, y, w, h, forceUpdate)
		leftEdgeX = leftEdgeX + w + self.spacing
	end

	local rightEdgeX = self.innerW / 2
	for _,child in ipairs(self.endChildren) do
		local x = rightEdgeX - w / 2
		allocateChild(self, child, x, y, w, h, forceUpdate)
		rightEdgeX = rightEdgeX - w - self.spacing
	end
end

local function allocateHeterogeneousRow(self, forceUpdate)
	local h = self.innerH
	local y = 0

	local childCount = #self.startChildren + #self.endChildren
	if childCount == 0 then  return  end

	local spacingSpace = self.spacing * (childCount - 1)
	local availableW = self.innerW - spacingSpace
	local totalChildW = getTotalChildrenWidth(self)
	local squashFactor = math.min(1, availableW / totalChildW)
	local extraW = math.max(0, availableW - totalChildW)
	local extraWidthFactor = extraW / getTotalGreedyChildrenWidth(self)

	local leftEdgeX = -self.innerW / 2
	for _,child in ipairs(self.startChildren) do
		local w = child.obj.designW * squashFactor
		if child.isGreedy then
			w = w + child.obj.designW * extraWidthFactor
		end
		local x = leftEdgeX + w / 2
		allocateChild(self, child, x, y, w, h, forceUpdate)
		leftEdgeX = leftEdgeX + w + self.spacing
	end

	local rightEdgeX = self.innerW / 2
	for _,child in ipairs(self.endChildren) do
		local w = child.obj.designW * squashFactor
		if child.isGreedy then
			w = w + child.obj.designW * extraWidthFactor
		end
		local x = rightEdgeX - w / 2
		allocateChild(self, child, x, y, w, h, forceUpdate)
		rightEdgeX = rightEdgeX - w - self.spacing
	end
end

function Row._updateChildren(self, forceUpdate)
	if self.homogeneous then
		allocateHomogeneousRow(self, forceUpdate)
	else
		allocateHeterogeneousRow(self, forceUpdate)
	end
	for i,child in ipairs(self.children) do
		-- Allocate any children not in the row as a normal Node.
		if not self.rowChildren[child] then
			child:call(
				'parentResized',
				self.designInnerW, self.designInnerH,
				self.innerW, self.innerH, self.scale, 0, 0, forceUpdate -- clear parentOffsetX/Y
			)
		end
	end
end

function Row.add(self, obj, dir, isGreedy, index)
	addChild(self, obj, dir, isGreedy, index)
	self:_updateChildren()
end

function Row.remove(self, obj)
	removeChild(self, obj)
	self:_updateChildren()
end

function Row.getChildIndex(self, obj)
	local list = self.rowChildren[obj]
	if not list then  return  end
	for i,childData in ipairs(list) do
		if childData.obj == obj then  return i  end
	end
end

Row.refresh = Row._updateChildren

function Row.init(self)
	if self.children then
		local didAdd = false
		for i,v in pairs(self.initChildren) do
			local obj = self.children[i]
			if obj then
				addChild(self, obj, v.dir, v.isGreedy, v.index)
				didAdd = true
			end
		end
		if didAdd then  self:_updateChildren()  end
	end
	self.initChildren = nil
	Row.super.init(self)
end

function Row.set(self, spacing, homogeneous, children, x, y, angle, w, h, px, py, ax, ay, resizeMode, padX, padY)
	Row.super.set(self, x, y, angle, w, h, px, py, ax, ay, resizeMode, padX, padY)
	self.spacing = spacing or 0
	self.homogeneous = homogeneous or false
	self.startChildren, self.endChildren = {}, {}
	self.rowChildren = {} -- sum of start- and end-children, by key instead of a list.
	self.initChildren = {}
	for _,child in ipairs(children or noChildren) do
		if type(child[1]) == "number" then
			self.initChildren[child[1]] = { dir = child[2], isGreedy = child[3], index = child[4]}
		else
			addChild(self, unpack(child))
		end
	end
end

return Row
