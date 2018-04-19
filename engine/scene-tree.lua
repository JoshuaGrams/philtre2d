local M = require('engine.matrix')

local function to_world(obj, x, y, w) -- @@@ keep as module function
	return M.x(obj._to_world, x, y, w)
end

local function to_local(obj, x, y, w) -- @@@ keep as module function
	if not obj._to_local then
		obj._to_local = M.invert(obj._to_world)
	end
	return M.x(obj._to_local, x, y, w)
end

local function init_child(self, obj, parent, index)
	obj.name = obj.name or tostring(index)
	obj.path = parent.path .. '/' .. obj.name
	if self.paths[obj.path] then -- Append index if identical path exists.
		obj.path = obj.path .. index
	end
	self.paths[obj.path] = obj
	obj.tree = self
	obj.parent = parent

	obj:update_transform()

	if obj.children then
		for i,c in pairs(obj.children) do
			init_child(self, c, obj, i)
		end
	end

	if obj.script and not obj.script[1] then
		obj.script = { obj.script }
	end
	obj('init')
end

local function _update(objects, dt, draw_order, m)
	for _,obj in pairs(objects) do
		local dt = dt and not obj.paused and dt or nil
		local draw_order = draw_order
		if dt then -- not paused at self or anywhere up the tree
			M.copy(m, obj._to_world);  obj._to_local = nil
			obj('update', dt)
			obj:update_transform()
		end
		if draw_order and obj.visible then
			draw_order:save_current_layer()
			draw_order:add(obj)
		else
			draw_order = nil -- don't draw any children from here on down
		end
		if obj.children then
			_update(obj.children, dt, draw_order, obj._to_world)
		end
		if draw_order then  draw_order:restore_current_layer()  end
	end
end

local function update(self, dt)
	if self.draw_order then  self.draw_order:clear()  end
	_update(self.children, dt, self.draw_order, self._to_world)
end

local function _draw(objects) -- only used if no draw_order
	for _,obj in pairs(objects) do
		if obj.pos then
			love.graphics.push()
			love.graphics.translate(obj.pos.x, obj.pos.y)
			love.graphics.scale(obj.sx or 1, obj.sy)
			love.graphics.rotate(obj.angle or 0)
			love.graphics.shear(obj.kx or 0, obj.ky or 0)
		end
		obj('draw')
		if obj.children then
			_draw(obj.children)
		end
		if obj.pos then love.graphics.pop() end
	end
end

local function draw(self)
	if self.draw_order then
		self.draw_order:draw()
	else
		_draw(self.children)
	end
end

-- This sets all the transforms, which seems like a waste,
-- because we're probably calling this from `update` which will
-- immediately do it all over again.  But an object's `init`
-- method may refer to them, so they need to be set now.
local function add(self, obj, parent) -- @@@ keep as module function
	parent = parent or self
	if not parent.children then parent.children = {} end
	local i = 1 + #parent.children
	parent.children[i] = obj
	init_child(self, obj, parent, i)
end

-- @@@ keep as module function (make `not_from_parent` bit private somehow?)
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
	obj('final')
	-- Ensure obj won't be drawn & children won't get another update.
	-- final() functions will be the final callback.
	-- @@@ make this part of object final function?
		-- should change to set_paused, set_visible
	obj.pos = false
	obj.draw = false
	obj.children = false
	self.paths[obj.path] = nil -- @@@ keep this
end

local function get(self, path) -- @@@ keep as module function - (also do relative paths somehow?)
	return self.paths[path]
end

local methods = {
	add = add, remove = remove, get = get,
	update = update, draw = draw,
	pause = pause, unpause = unpause
}
local class = { __index = methods }

local function new(draw_order, root_objects) -- @@@ Get rid of this - store singular scene-tree state in module
	local tree = setmetatable({
		_to_world = M.identity, _to_local = M.identity,
		pos = {x=0, y=0},
		children = root_objects,
		draw_order = draw_order,
		path = '', paths = {},
	}, class)
	for i,c in pairs(tree.children) do
		init_child(tree, c, tree, i)
	end
	return tree
end


local T = {
	object = object,  new = new,
	methods = methods,  class = class,
	to_world = to_world,  to_local = to_local
}

return T
