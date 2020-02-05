local base = (...):gsub('[^%.]+$', '')
local Class = require(base .. 'lib.base-class')
local DepthList = require(base .. 'depth-list')
local Layer = require(base .. 'layer')

local DrawOrder = Class:extend()

local onlyGroup = 'all'

function DrawOrder.set(self, groups, default)
	self.groups = {}
	self.layers = {}
	self.stack = {}
	self.layer = false
	local _,g = next(groups)
	if type(g) ~= 'table' then
		groups = { [onlyGroup] = groups }
	end
	for name,group in pairs(groups) do
		local g = DepthList()
		self.groups[name] = g
		for _,layer in ipairs(group) do
			local l = Layer()
			self.layers[layer] = l
			if not self.layer then self.layer = l end
			g:add(l, 'bottom')
		end
	end
	self.layer = (default and self.layers[default]) or self.layer
end

function DrawOrder.draw(self, groups)
	assert(groups, 'DrawOrder.draw - Must specify which group(s) to draw.')
	if type(groups) ~= 'table' then
		groups = { groups or onlyGroup }
	end
	-- Loop backwards so first group is on top.
	for i=#groups,1,-1 do
		local group = groups[i]
		self.groups[group]:draw()
	end
end

function DrawOrder.addLayer(self, name, position, other)
	local layer = self.layers[name]
	if other then other = self.layers[other] end
	layer.group:add(layer, position, other)
end

function DrawOrder.removeLayer(self, name)
	local layer = self.layers[name]
	layer.group:remove(layer)
end

function DrawOrder.addFunction(self, layer, m, fn, ...)
	self.layer = self.layers[layer]
	self.layer:addFunction(m, fn, ...)
end

function DrawOrder.addObject(self, object)
	self.layer = self.layers[object.layer] or self.layer
	self.layer:addObject(object)
end

function DrawOrder.clear(self)
	for _,group in pairs(self.groups) do
		group:clear()
	end
end

function DrawOrder.saveCurrentLayer(self)
	table.insert(self.stack, self.layer)
end

function DrawOrder.restoreCurrentLayer(self)
	self.layer = table.remove(self.stack)
end

return DrawOrder
