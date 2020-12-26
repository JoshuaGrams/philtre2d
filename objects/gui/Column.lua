local base = (...):gsub('[^%.]+$', '')
local Node = require(base .. 'Node')

local Column = Node:extend()
Column.className = "Column"

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

local function _sumHeights(child, val)
	return val + child.obj.designH
end

local function getTotalChildrenHeight(self)
	return iterateOverChildren(self, _sumHeights, 0)
end

local function _sumGreedyHeights(child, val)
	if child.isGreedy then  return val + child.obj.designH  end
end

local function getTotalGreedyChildrenHeight(self)
	return iterateOverChildren(self, _sumGreedyHeights, 0)
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

local function allocateHomogeneousColumn(self, forceUpdate)
	local w = self.innerW
	local x = 0

	local childCount = #self.startChildren + #self.endChildren
	if childCount == 0 then  return  end

	local spacingSpace = self.spacing * (childCount - 1)
	local h = math.max(0, (self.innerW - spacingSpace) / childCount)

	local topEdgeY = -self.innerH / 2 -- No spacing at ends, only in between.
	for _,child in ipairs(self.startChildren) do
		local y = topEdgeY + h / 2
		allocateChild(self, child, x, y, w, h, forceUpdate)
		topEdgeY = topEdgeY + h + self.spacing
	end

	local botEdgeY = self.innerH / 2
	for _,child in ipairs(self.endChildren) do
		local y = botEdgeY - h / 2
		allocateChild(self, child, x, y, w, h, forceUpdate)
		botEdgeY = botEdgeY - h - self.spacing
	end
end

local function allocateHeterogeneousColumn(self, forceUpdate)
	local w = self.innerW
	local x = 0

	local childCount = #self.startChildren + #self.endChildren
	if childCount == 0 then  return  end

	local spacingSpace = self.spacing * (childCount - 1)
	local availableH = self.innerH - spacingSpace
	local totalChildH = getTotalChildrenHeight(self)
	local squashFactor = math.min(1, availableH / totalChildH)
	local extraH = math.max(0, availableH - totalChildH)
	local extraHeightFactor = extraH / getTotalGreedyChildrenHeight(self)

	local topEdgeY = -self.innerH / 2
	for _,child in ipairs(self.startChildren) do
		local h = child.obj.designH * squashFactor
		if child.isGreedy then
			h = h + child.obj.designH * extraHeightFactor
		end
		local y = topEdgeY + h / 2
		allocateChild(self, child, x, y, w, h, forceUpdate)
		topEdgeY = topEdgeY + h + self.spacing
	end

	local botEdgeY = self.innerH / 2
	for _,child in ipairs(self.endChildren) do
		local h = child.obj.designH * squashFactor
		if child.isGreedy then
			h = h + child.obj.designH * extraHeightFactor
		end
		local y = botEdgeY - h / 2
		allocateChild(self, child, x, y, w, h, forceUpdate)
		botEdgeY = botEdgeY - h - self.spacing
	end
end

function Column._updateChildren(self, forceUpdate)
	if self.homogeneous then
		allocateHomogeneousColumn(self, forceUpdate)
	else
		allocateHeterogeneousColumn(self, forceUpdate)
	end
	for i,child in ipairs(self.children) do
		-- Allocate any children -not in the row- as if we were a normal Node.
		if not self.rowChildren[child] then
			child:call(
				'parentResized',
				self.designInnerW, self.designInnerH,
				self.innerW, self.innerH, self.scale, 0, 0, forceUpdate -- clear parentOffsetX/Y
			)
		end
	end
end

function Column.add(self, obj, dir, isGreedy, index)
	addChild(self, obj, dir, isGreedy, index)
	self:_updateChildren()
end

function Column.remove(self, obj)
	removeChild(self, obj)
	self:_updateChildren()
end

function Column.getChildIndex(self, obj)
	local list = self.rowChildren[obj]
	if not list then  return  end
	for i,childData in ipairs(list) do
		if childData.obj == obj then  return i  end
	end
end

Column.refresh = Column._updateChildren

function Column.init(self)
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
	Column.super.init(self)
end

function Column.set(self, spacing, homogeneous, children, x, y, angle, w, h, px, py, ax, ay, resizeMode, padX, padY)
	Column.super.set(self, x, y, angle, w, h, px, py, ax, ay, resizeMode, padX, padY)
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

return Column
