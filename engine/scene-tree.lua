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

-- Create a table with all the transform properties.
local function object(x, y, angle, sx, sy, kx, ky)
	return {
		pos = { x = x or 0, y = y or 0 },
		angle = angle or 0,
		sx = sx or 1,
		sy = sy or sx or 1,
		kx = kx or 0,
		ky = ky or 0
	}
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

-- Add local transform to `parent` world transform.
local function coords(parent, obj)
	if obj.absolute_coords then parent = M.identity end
	local m = M.matrix(obj.pos.x, obj.pos.y, obj.angle, obj.sx, obj.sy)
	return M.xM(m, parent,  m)
end

local function init_child(self, obj, parent, index)
	obj.name = obj.name or tostring(index)
	obj.path = parent.path .. '/' .. obj.name
	-- Check for objects with identical names on the same parent
	if self.paths[obj.path] then
		obj.path = obj.path .. index
	end
	self.paths[obj.path] = obj
	-- Add reference to current scene-tree
	obj.tree = self

	-- Skip nodes with no transform.  Since we do this every
	-- step, our grandparent is guaranteed to have a transform.
	if not parent.pos then
		parent = parent.parent
		table.insert(parent.children, obj)
	end
	obj.parent = parent
	-- TODO - Oh, man.  That doesn't remove the parent from its
	-- parent's children array, so all children of nodes with
	-- no transform will be processed twice.  Plus, if we *do*
	-- remove it from the tree completely, its update function
	-- won't be called.  Is that a problem?  It doesn't have a
	-- transform, so presumably we don't want to draw it, but
	-- we might want to update it somehow?  Or are they just a
	-- load-time thing?
	--
	-- And if we do remove it, then either it will potentially
	-- screw up future paths (by renumbering existing objects so
	-- the last number could be re-used) or screw up looping
	-- over the children.  So we might have to rewrite this to
	-- work from the top down, removing the pure collection
	-- before any later siblings are initialized.  Bleh.

	local m = parent._to_world
	local n = obj.pos and coords(m, obj) or m
	obj._to_world, obj._to_local = n, nil
	if obj.children then
		for i,o in pairs(obj.children) do
			init_child(self, o, obj, i)
		end
	end
	if obj.init then obj:init() end
	-- Convert script to list of scripts, call init on all of them.
	if obj.script then
		if not obj.script[1] then obj.script = { obj.script } end
		for _,script in ipairs(obj.script) do
			if script.init then script.init(obj) end
		end
	end
end

local function _update(objects, dt, draw_order, m)
	for _,o in pairs(objects) do
		if not o.paused then
			o._to_world, o._to_local = m, nil
			if o.update then o:update(dt) end
			if o.script then
				for _,script in ipairs(o.script) do
					if script.update then script.update(o, dt) end
				end
			end
			if o.pos then
				o._to_world, o._to_local = coords(m, o), nil
			end
		end
		if draw_order and o.draw then
			draw_order:save_current_layer()
			draw_order:add(o)
		end
		if o.children then
			_update(o.children, dt, draw_order, o._to_world)
		end
		if draw_order and o.draw then
			draw_order:restore_current_layer()
		end
	end
end

local function update(self, dt)
	if self.draw_order then  draw_order:clear()  end
	_update(self.children, dt, self.draw_order, self._to_world)
end

local function _draw(objects)
	for _,o in pairs(objects) do
		if o.pos then
			love.graphics.push()
			love.graphics.translate(o.pos.x, o.pos.y)
			love.graphics.scale(o.sx or 1, o.sy)
			love.graphics.rotate(o.angle or 0)
			love.graphics.shear(o.kx or 0, o.ky or 0)
		end
		if o.draw then o:draw() end
		if o.script then
			for _,script in ipairs(o.script) do
				if script.draw then script.draw(o) end
			end
		end
		if o.children then
			_draw(o.children)
		end
		if o.pos then love.graphics.pop() end
	end
end

local function draw(self)
	if self.draw_order then
		draw_order:draw()
	else
		_draw(self.children)
	end
end

-- This sets all the transforms, which seems like a waste,
-- because we're probably calling this from `update` which will
-- immediately do it all over again.  But an object's `init`
-- method may refer to them, so they need to be set now.
local function add(self, obj, parent)
	parent = parent or self
	if not parent.children then parent.children = {} end
	local i = 1 + #parent.children
	parent.children[i] = obj
	init_child(self, obj, parent, i)
end

local function remove(self, obj, not_from_parent)
	if not not_from_parent then -- remove obj from parent's child list
		local parent = obj.parent
		for i,c in pairs(parent.children) do
			if c == obj then
				parent.children[i] = nil
				break
			end
		end
	end
	-- delete all children down the tree
	-- don't bother telling children to delete themselves from our child list
	if obj.children then
		for i,c in pairs(obj.children) do
			self:remove(c, true)
		end
	end
	if obj.final then obj:final() end
	if obj.script then
		for _,script in ipairs(obj.script) do
			if script.final then script.final(obj) end
		end
	end
	-- Ensure obj won't be drawn & children won't get another update.
	-- final() functions will be the final callback.
	obj.pos = false
	obj.draw = false
	obj.children = false
	self.paths[obj.path] = nil
end

local function get(self, path)
	return self.paths[path]
end

local function pause(self, obj)
	obj.paused = true
	if obj.children then
		for i,c in pairs(obj.children) do
			pause(self, c)
		end
	end
end

local function unpause(self, obj)
	obj.paused = false
	if obj.children then
		for i,c in pairs(obj.children) do
			unpause(self, c)
		end
	end
end

local methods = {
	add = add, remove = remove, get = get,
	update = update, draw = draw,
	pause = pause, unpause = unpause
}
local class = { __index = methods }

local function new(draw_order, root_objects)
	local tree = setmetatable({
		_to_world = M.identity, _to_local = M.identity,
		pos = {x=0, y=0},
		children = root_objects,
		draw_order = draw_order,
		path = '', paths = {},
	}, class)
	for i,o in pairs(tree.children) do
		init_child(tree, o, tree, i)
	end
	return tree
end


local T = {
	mod = mod,  object = object,
	new = new, methods = methods, class = class,
	to_world = to_world,  to_local = to_local
}

return T
