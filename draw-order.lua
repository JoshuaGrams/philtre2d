local M = require('matrix')

local function add_layer(self, name, behind)
	local layer = { name = name, n = 0 }
	if self.layers[name] ~= nil then
		error("Layer \"" .. name .. "\" already exists.")
	else
		self.layers[name] = layer  -- insert by name
		for i,layer in ipairs(self.layers) do  -- insert by depth
			if layer.name == behind then
				table.insert(self.layers, i+1, layer)
				return
			end
		end
		table.insert(self.layers, 1, layer)
	end
end

local function remove_layer(self, name)
	if not self.layers[name] then
		error("No such layer \"" .. name .. "\".")
	else
		local layer = self.layers[name]
		self.layers[name] = nil
		for i,l in ipairs(self.layers) do
			if l == layer then
				table.remove(self.layers, i)
				return
			end
		end
	end
end

local function reset(self)
	for i,layer in ipairs(self.layers) do
		layer.n = 0
	end
end

local function add(self, object)
	local layer = self.layers[object.layer or self.default_layer]
	layer.n = layer.n + 1
	layer[layer.n] = object
end

local function draw(self)
	love.graphics.push()
	local m = nil
	for _,layer in ipairs(self.layers) do
		for _,object in ipairs(layer) do
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
	reset = reset,
	add = add,
	draw = draw
}
local class = { __index = methods }

local function new(default_layer_name)
	default_layer_name = default_layer_name or 'default'
	local draw_order = setmetatable({
		default_layer = default_layer_name,
		layers = {}
	}, class)
	add_layer(draw_order, default_layer_name)
	return draw_order
end

return { new = new, methods = methods, class = class }
