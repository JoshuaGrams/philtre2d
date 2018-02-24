-- Supports named layers and depths.  Objects may have a `layer`
-- property giving a layer name, or a `depth` property (greater
-- depths are farther into the screen).
--
-- Named layers must be added prior to use:
--
-- * order:add_layer(depth, name)
--
-- * order:remove_layer(name)
--
-- Within a layer, objects are drawn in the order they are
-- added.  Each frame, you will want to clear the order, add
-- objects, and then draw the whole thing:
--
-- * order:clear()
--
-- * order:add(object)
--
-- * order:draw()

local M = require('matrix')

local function add_layer(self, depth, name)
	local layer = { name = name, depth = depth, n = 0 }
	if name and self.named[name] ~= nil then
		error("Layer \"" .. name .. "\" already exists.")
	else
		self.named[name] = layer  -- insert by name
		self.depth[depth] = layer -- and by depth
	end
	return layer
end

local function remove_layer(self, name)
	local layer = self.named[name]
	if not layer then
		error("No such layer \"" .. name .. "\".")
	else
		self.named[name] = nil
		self.depth[layer.depth] = nil
	end
end

local function clear(self)
	for depth,layer in pairs(self.depth) do
		layer.n = 0
	end
end

local function object_layer(self, object)
	local layer
	if object.depth then
		layer = self.depth[object.depth] or add_layer(self, object.depth)
	elseif object.layer then
		layer = self.named[object.layer]
		if not layer then
			error('No such layer "' .. object.layer .. '".')
		end
	else
		layer = self.named[self.default_layer]
	end
	return layer
end

local function add(self, object)
	local layer = object_layer(self, object)
	layer.n = layer.n + 1
	layer[layer.n] = object
end

local function depths(self)
	local n, order = 0, self.order
	for depth,layer in pairs(self.depth) do
		n = n + 1
		order[n] = depth
	end
	for i=n+1,order.n do order[i] = nil end
	order.n = n
	table.sort(order)
	return order
end

local function draw(self)
	love.graphics.push()
	local m = nil
	for _,depth in ipairs(depths(self)) do
		for _,object in ipairs(self.depth[depth]) do
			if m ~= object._to_world then
				m = object._to_world
				if not m.th then
					m.th, m.sx, m.sy, m.kx, m.ky = M.parameters(m)
				end
				love.graphics.origin()
				love.graphics.translate(m.x, m.y)
				love.graphics.rotate(m.th)
				love.graphics.scale(m.sx, m.sy)
				love.graphics.shear(m.kx, m.ky)
			end
			object:draw()
		end
	end
	love.graphics.pop()
end

local methods = {
	add_layer = add_layer,
	remove_layer = remove_layer,
	clear = clear,
	add = add,
	draw = draw
}
local class = { __index = methods }

local function new(default_name, default_depth)
	default_name = default_name or 'default'
	default_depth = default_depth or 0
	local draw_order = setmetatable({
		default_layer = default_name,
		named = {}, depth = {},
		order = { n = 0 }
	}, class)
	add_layer(draw_order, default_depth, default_name)
	return draw_order
end

return { new = new, methods = methods, class = class }
