local M = require('engine.matrix')

-- Note that `props` override values already on `obj`.  This is
-- deliberate, so we can insert a file into a bigger scene and
-- then customize it.
local function mod(obj, props)
	for name,prop in pairs(props) do
		obj[name] = prop
	end
	return obj
end

local function to_world(obj, x, y, w)
	return M.x(obj._to_world, x, y, w)
end

local function to_local(obj, x, y, w)
	if not obj._to_local then
		obj._to_local = M.invert(obj._to_world)
	end
	return M.x(obj._to_local, x, y, w)
end

-- Add local transform to `old` world transform.
local function coords(old, obj)
	local m = M.matrix(obj.pos.x, obj.pos.y, obj.angle, obj.sx, obj.sy)
	m = M.xM(m, old, m)
	return m
end

local init
local function init_child(child, parent, index, paths, m)
	child.parent = parent

	local path = parent and parent.path or ''
	child.name = child.name or tostring(index)
	child.path = path .. '/' .. child.name

	m = m or M.identity
	local n = child.pos and coords(m, child) or m
	if child.children then
		init(child.children, n, child, paths)
	end
	if child.init then child:init() end
end

init = function (graph, m, parent, paths)
	m = m or M.identity
	parent = parent or nil
	paths = paths or {}
	local path = parent and parent.path or ''
	for i,o in ipairs(graph) do
		init_child(o, parent, i, paths, m)
	end
	return paths
end

local function update(graph, dt, draw_order, m)
	m = m or M.identity
	for _,o in ipairs(graph) do
		o._to_world, o._to_local = m, nil
		if o.update then o:update(dt) end
		if o.pos then
			o._to_world, o._to_local = coords(m, o), nil
		end
		if draw_order and o.draw then
			draw_order:save_current_layer()
			draw_order:add(o)
		end
		if o.children then
			update(o.children, dt, draw_order, o._to_world)
		end
		if draw_order and o.draw then
			draw_order:restore_current_layer()
		end
	end
end

local function draw(graph)
	for _,o in ipairs(graph) do
		if o.pos then
			love.graphics.push()
			love.graphics.translate(o.pos.x, o.pos.y)
			love.graphics.scale(o.sx or 1, o.sy)
			love.graphics.rotate(o.angle or 0)
		end
		if o.draw then o:draw() end
		if o.children then
			draw(o.children)
		end
		if o.pos then love.graphics.pop() end
	end
end

-- This sets all the transforms, which seems like a waste,
-- because we're probably calling this from `update` which will
-- immediately do it all over again.  But an object's `init`
-- method may refer to them, so they need to be set now.
local function add_child(child, parent, paths)
	if not parent then error("Must have a parent") end
	if not parent.children then parent.children = {} end
	local i = #parent.children
	table.insert(parent.children, i, child)
	init_child(child, parent, i, paths, parent._to_world)
end

local function remove_child(child, paths)
	local parent = child.parent
	for i,c in ipairs(parent.children) do
		if c == child then
			parent.children = nil
			break
		end
	end
	paths[child.path] = nil
end

local T = {
	mod = mod,
	to_world = to_world,  to_local = to_local,
	init = init,  update = update,  draw = draw,
}

return T
