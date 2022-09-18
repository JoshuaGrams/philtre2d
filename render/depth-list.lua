local base = (...):gsub('render%.depth%-list$', '')
local Class = require(base .. 'core.base-class')

local DepthList = Class:extend()
DepthList.className = 'DepthList'

function DepthList.draw(self)
	local layer = self.bottom.above
	while layer ~= self.top do
		layer:draw()
		layer = layer.above
	end
end

function DepthList.clear(self)
	local layer = self.bottom.above
	while layer ~= self.top do
		layer:clear()
		layer = layer.above
	end
end

function DepthList.remove(self, layer)
	layer.above.below = layer.below
	layer.below.above = layer.above
end

local function add(self, layer, position, other)
	local above, below
	if position == 'top' then
		above, below = self.top, self.top.below
	elseif position == 'bottom' then
		above, below = self.bottom.above, self.bottom
	elseif position == 'above' then
		above, below = other.above, other
	elseif position == 'below' then
		above, below = other, other.below
	end

	layer.above, layer.below = above, below
	above.below, below.above = layer, layer

	layer.group = self

	return layer
end
DepthList.add = add

local none = {}

function DepthList.set(self, layers)
	self.top, self.bottom = {}, {}
	self.top.below, self.bottom.above = self.bottom, self.top
	for _,layer in ipairs(layers or none) do
		add(self, layer, 'bottom')
	end
end

return DepthList
