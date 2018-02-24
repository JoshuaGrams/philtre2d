-- A scene graph is simply a sequence (table) of objects, each of
-- which may have a bunch of optional properties:
--
-- * children = {obj1, obj2, ...}
-- * p = {x=0, y=0}   -- position
-- * angle = 0        -- radians
-- * sx, sy = 1, nil  -- scale (uniformly if sy is nil)
--
-- When updating, each object's `_to_world` property is set to
-- the appropriate matrix.

local M = require('matrix')

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
	local m = M.matrix(obj.p.x, obj.p.y, obj.angle, obj.sx, obj.sy)
	m = M.xM(m, old, m)
	return m
end

local function init(graph, m, parent)
	m = m or M.identity
	parent = parent or nil
	for _,o in ipairs(graph) do
		o.parent = parent
		local n = o.p and coords(m, o) or m
		o._to_world, o._to_local = n, nil
		if o.children then
			init(o.children, n, o)
		end
		if o.init then o:init() end
	end
end

local function update(graph, dt, draw_order, m)
	m = m or M.identity
	for _,o in ipairs(graph) do
		o._to_world, o._to_local = m, nil
		if o.update then o:update(dt) end
		if o.p then
			o._to_world, o._to_local = coords(m, o), nil
		end
		if draw_order and o.draw then
			draw_order:add(o)
		end
		if o.children then
			update(o.children, dt, draw_order, o._to_world)
		end
	end
end

local function draw(graph)
	for _,o in ipairs(graph) do
		if o.p then
			love.graphics.push()
			love.graphics.translate(o.p.x, o.p.y)
			love.graphics.scale(o.sx or 1, o.sy)
			love.graphics.rotate(o.angle or 0)
		end
		if o.draw then o:draw() end
		if o.children then
			draw(o.children)
		end
		if o.p then love.graphics.pop() end
	end
end

local G = {
	config = config,
	to_world = to_world,  to_local = to_local,
	init = init,  update = update,  draw = draw,
}

return G
