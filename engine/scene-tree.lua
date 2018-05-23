local M = require('engine.matrix')

local tree = {
	_to_world = M.identity,
	_to_local = M.identity,
	pos = {x=0, y=0},
	children = {},
	path = '',
	paths = {},
}

local reparents = {} -- to complete on next pre-/post-update

local function toWorld(obj, x, y, w)
	return M.x(obj._to_world, x, y, w)
end

local function toLocal(obj, x, y, w)
	if not obj._to_local then
		obj._to_local = M.invert(obj._to_world)
	end
	return M.x(obj._to_local, x, y, w)
end

local function init(draw_order)
	tree.draw_order = draw_order
end

local function initChild(obj, parent, index)
	obj.name = obj.name or tostring(index)
	obj.path = parent.path .. '/' .. obj.name
	if tree.paths[obj.path] then -- Append index if identical path exists.
		obj.path = obj.path .. index
	end
	tree.paths[obj.path] = obj
	obj.tree = tree
	obj.parent = parent

	obj:updateTransform()

	if obj.children then
		for i,c in pairs(obj.children) do
			initChild(c, obj, i)
		end
	end

	if obj.script and not obj.script[1] then
		obj.script = { obj.script }
	end
	obj:call('init')
end

-- Actually swap obj between new and old parents' child lists.
local function completeReparenting()
	for key,v in pairs(reparents) do
		v.old_p.children[v.old_child_key] = nil
		if not v.new_p.children then v.new_p.children = {} end
		local i = 1 + #v.new_p.children
		v.new_p.children[i] = v.obj
		reparents[key] = nil
	end
end

local function preUpdate(dt)
	completeReparenting()
end

local function _update(objects, dt, draw_order, m)
	for _,obj in pairs(objects) do
		local dt = dt and not obj.paused and dt or nil
		local draw_order = draw_order
		if dt then -- not paused at self or anywhere up the tree
			M.copy(m, obj._to_world);  obj._to_local = nil
			obj:call('update', dt)
			obj:updateTransform()
		end
		if draw_order and obj.visible then
			draw_order:saveCurrentLayer()
			draw_order:addObject(obj)
		else
			draw_order = nil -- don't draw any children from here on down
		end
		if obj.children then
			_update(obj.children, dt, draw_order, obj._to_world)
		end
		if draw_order then  draw_order:restoreCurrentLayer()  end
	end
end

local function postUpdate(dt)
	completeReparenting()
end

local function update(dt)
	if tree.draw_order then  tree.draw_order:clear()  end
	preUpdate(dt)
	_update(tree.children, dt, tree.draw_order, tree._to_world)
	postUpdate(dt)
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
		obj:call('draw')
		if obj.children then
			_draw(obj.children)
		end
		if obj.pos then love.graphics.pop() end
	end
end

local function draw()
	if tree.draw_order then
		tree.draw_order:draw()
	else
		_draw(tree.children)
	end
end

-- This sets all the transforms, which seems like a waste,
-- because we're probably calling this from `update` which will
-- immediately do it all over again.  But an object's `init`
-- method may refer to them, so they need to be set now.
local function add(obj, parent)
	parent = parent or tree
	if not parent.children then parent.children = {} end
	local i = 1 + #parent.children
	parent.children[i] = obj
	initChild(obj, parent, i)
end

-- TODO make `not_from_parent` bit private somehow?

local function remove(obj, not_from_parent)
	if not not_from_parent then -- remove obj from parent's child list
		local parent = obj.parent
		for i,c in pairs(parent.children) do
			if c == obj then
				parent.children[i] = nil
				break
			end
		end
	end
	if obj.children then
		for i,c in pairs(obj.children) do
			-- All descendants will be removed, tell them not to bother
			-- to delete themselves from their parent's child list.
			remove(c, true)
			-- Must clear the child list because scene-tree may already
			-- have its reference and be updating through it.
			obj.children[i] = nil
		end
	end
	obj:call('final')
	-- Ensure that `final` is the last callback for obj, its scripts, and its children
	obj.draw = false -- obj won't draw even if already in the draw order this frame
	obj.script = false -- scripts won't do anything else either
	obj.visible = false -- obj and children won't be added to draw order after this
	tree.paths[obj.path] = nil
end

-- Can't complete this synchronously or obj would miss a callback
-- or get an extra callback. Switch the parent on obj now and
-- change the child lists on the next pre- or post-update.
local function setParent(obj, parent)
	parent = parent or tree
	if parent == obj.parent then
		print('Tried to set_parent to current parent: ' .. parent.path)
		return
	end
	for k,c in pairs(obj.parent.children) do
		if c == obj then
			table.insert(reparents, { obj=obj, old_p=obj.parent, old_child_key=k, new_p=parent })
			obj.parent = parent
			return
		end
	end
	error('scene.set_parent - could not find child "' .. obj.path .. '" in parent ("' .. parent.path .. '") child list.')
end

local function get(path) -- TODO - Relative paths?
	return tree.paths[path]
end


local T = {
	toWorld = toWorld,  toLocal = toLocal,
	update = update,  draw = draw,  add = add,
	remove = remove,  get = get,  init = init,
	setParent = setParent
}

return T
