local base = (...):gsub('render%.draw%-order$', '')
local Class = require(base .. 'core.base-class')
local Layer = require(base .. 'render.layer')

local DrawOrder = Class:extend()

local onlyGroup = 'all'

function DrawOrder.set(self, groups, default)
	self.groups = {}
	self.layers = {}
	self.stack = {}
	self.layer = false
	local containsDefaultLayer = false
	local _,g = next(groups)
	if type(g) ~= 'table' then
		groups = { [onlyGroup] = groups }
	end
	for groupName,layerNames in pairs(groups) do
		local group = {}
		self.groups[groupName] = group
		for _,layerName in ipairs(layerNames) do
			if layerName == default then  containsDefaultLayer = true  end
			local layer = Layer()
			self.layers[layerName] = layer
			if not self.layer then self.layer = layer end -- Set layer to the first one in the first group in case there is no default.
			table.insert(group, layer)
		end
	end
	self.layer = (default and self.layers[default]) or self.layer
	assert(containsDefaultLayer, 'DrawOrder.set - Default layer: "'..tostring(default)..'" not found in layer groups.')
end

local function drawGroup(group)
	for i=#group,1,-1 do
		group[i]:draw()
	end
end

function DrawOrder.draw(self, groups)
	if type(groups) ~= 'table' then
		groups = { groups or onlyGroup }
	end
	assert(groups, 'DrawOrder.draw - Must specify which group(s) to draw.')
	-- Loop backwards so first group is on top.
	for i=#groups,1,-1 do
		local group = groups[i]
		drawGroup(self.groups[group])
	end
end

function DrawOrder.addLayer(self, name, index)
	local layer = self.layers[name]
	if index then
		table.insert(layer.group, index, layer)
	else
		table.insert(layer.group, layer)
	end
end

function DrawOrder.removeLayer(self, name)
	local layer = self.layers[name]
	for i,l in ipairs(layer.group) do
		if l == layer then
			return table.remove(layer.group, i)
		end
	end
end

function DrawOrder.addFunction(self, layer, m, fn, ...)
	local layer = self.layers[layer] -- Keep local, no need to mess with the layer stack.
	layer:addFunction(m, fn, ...)
end

function DrawOrder.clear(self, layer)
	if layer then -- For only clearing one layer.
		assert(self.layers[layer], 'DrawOrder.clear - Can\'t clear layer: "' .. tostring(layer) .. '", it doesn\'t exist.')
		self.layers[layer]:clear()
		return
	end
	for i=1,#self.groups do
		self.groups[i] = {}
	end
end

function DrawOrder.saveCurrentLayer(self)
	table.insert(self.stack, self.layer)
end

function DrawOrder.restoreCurrentLayer(self)
	self.layer = table.remove(self.stack)
end

local function getInheritedLayerName(tree, obj)
	if obj.layer then  return obj.layer  end
	local p = obj.parent
	while not p.layer do
		if p == tree then  return  end
		p = p.parent
	end
	return p.layer
end

local function getInheritedVisibility(tree, obj)
	while obj.visible do
		obj = obj.parent
		if obj == tree then  return true  end
	end
	return false
end

local function addObject(self, object)
	if object.visible and not object.drawIndex then
		self:saveCurrentLayer()
		if object.layer then
			self.layer = self.layers[object.layer]
			if not self.layer then
				error('DrawOrder.addObject - Layer "'..tostring(object.layer)..'" not found, from object: '..tostring(object))
			end
		end
		self.layer:addObject(object)
		if object.children then
			for i=1,object.children.maxn do
				local child = object.children[i]
				if child then  addObject(self, child)  end
			end
		end
		self:restoreCurrentLayer()
	end
end

function DrawOrder.addObject(self, object)
	if getInheritedVisibility(object.tree, object) then
		self:saveCurrentLayer()
		local layerName = getInheritedLayerName(object.tree, object)
		self.layer = self.layers[layerName] or self.layer

		addObject(self, object)

		self:restoreCurrentLayer()
	end
end

local function removeObject(self, object)
	if not object.visible then  return  end
	self:saveCurrentLayer()
	self.layer = self.layers[object.layer] or self.layer
	self.layer:removeObject(object)
	if object.children then
		for i=1,object.children.maxn do
			local child = object.children[i]
			if child then  removeObject(self, child)  end
		end
	end
	self:restoreCurrentLayer()
end

function DrawOrder.removeObject(self, object)
	self:saveCurrentLayer()
	local layerName = getInheritedLayerName(object.tree, object)
	self.layer = self.layers[layerName] or self.layer

	removeObject(self, object)

	self:restoreCurrentLayer()
end

function DrawOrder.moveObject(self, object, toLayer)
	local layerName = getInheritedLayerName(object.tree, object)
	if toLayer == layerName then  return  end
	self:removeObject(object)
	object.layer = toLayer
	self:addObject(object)
end

function DrawOrder.showObject(self, object)
	if getInheritedVisibility(object.tree, object) then
		self:addObject(object)
	end
end

return DrawOrder
