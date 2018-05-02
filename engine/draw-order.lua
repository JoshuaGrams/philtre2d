local M = require('engine.matrix')

local function addLayer(self, depth, name)
	local layer = { name = name, depth = depth, n = 0 }
	if name and self.named[name] ~= nil then
		error("Layer \"" .. name .. "\" already exists.")
	else
		if name then  self.named[name] = layer  end -- insert by name
		self.depth[depth] = layer -- and by depth
	end
	return layer
end

local function removeLayer(self, name)
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
		for i, v in ipairs(layer) do layer[i] = nil end
		if layer.n == 0 and not layer.name then
			-- Wasn't used last frame and doesn't have a name.
			self.depth[depth] = nil
		end
		layer.n = 0
	end
end

local function objectLayer(self, object)
	local layer
	local t = type(object.layer)
	if t == 'number' then
		layer = self.depth[object.layer] or addLayer(self, object.layer)
	elseif t == 'string' then
		layer = self.named[object.layer]
		if not layer then
			error('No such layer "' .. object.layer .. '".')
		end
	else
		layer = self.current_layer
	end
	return layer
end

local function addFunction(self, layer, m, fn, ...)
	self.current_layer = layer
	layer.n = layer.n + 1
	layer[layer.n] = {m = m, fn, ...}
end

local function add(self, object)
	local layer = objectLayer(self, object)
	local m = object._to_world
	addFunction(self, layer, m, object.call, object, 'draw')
end

local function saveCurrentLayer(self)
	table.insert(self.saved_layers, self.current_layer)
end

local function restoreCurrentLayer(self)
	self.current_layer = table.remove(self.saved_layers)
end

local function depths(self, depths)
	local n, order = 0, self.order
	for depth,layer in pairs(depths) do
		n = n + 1
		order[n] = depth
	end
	for i=n+1,order.n do order[i] = nil end
	order.n = n
	-- sort descending so greatest depths get drawn first
	-- (and lesser depths get drawn on top).
	table.sort(order, function(a,b) return a > b end)
	return order
end

local function draw(self, depth_list)
	love.graphics.push()
	local m = nil
	if not depth_list then  depth_list = self.depth  end
	for _,depth in ipairs(depths(self, depth_list)) do
		for _,fn in ipairs(self.depth[depth]) do
			local pushed
			if m ~= fn.m then
				m = fn.m
				local th, sx, sy, kx, ky = M.parameters(m)
				pushed = true
				love.graphics.push()
				love.graphics.translate(m.x, m.y)
				love.graphics.rotate(th)
				love.graphics.scale(sx, sy)
				love.graphics.shear(kx, ky)
			end
			fn[1](unpack(fn, 2))
			if pushed then love.graphics.pop() end
		end
	end
	love.graphics.pop()
end

local methods = {
	addLayer = addLayer,
	removeLayer = removeLayer,
	clear = clear,
	addFunction = addFunction,
	add = add,
	saveCurrentLayer = saveCurrentLayer,
	restoreCurrentLayer = restoreCurrentLayer,
	draw = draw
}
local class = { __index = methods }

local function new(default_name, default_depth)
	default_name = default_name or 'default'
	default_depth = default_depth or 0
	local draw_order = setmetatable({
		default_layer = default_name,
		saved_layers = {},
		named = {}, depth = {},
		order = { n = 0 }
	}, class)
	addLayer(draw_order, default_depth, default_name)
	draw_order.current_layer = draw_order.named[default_name]
	return draw_order
end

return { new = new, methods = methods, class = class }
