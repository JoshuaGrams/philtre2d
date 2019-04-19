local base = (...):gsub('[^%.]+$', '')
local M = require(base .. 'matrix')
local Class = require(base .. 'lib.base-class')
local Object = require(base .. 'Object')

local SceneTree = Class:extend()

function SceneTree.set(self, groups, default)
	self.draw_order = DrawOrder(groups, default)
	self._to_world = M.identity
	self._to_local = M.identity
	self.pos = {x=0, y=0}
	self.children = {}
	self.path = ''
	self.paths = {}
	self.removed = {}    -- finalize on next pre-/post-update
	self.reparents = {}  -- to complete on next pre-/post-update
end

local function initChild(tree, obj, parent, index)
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
			initChild(tree, c, obj, i)
		end
	end

	if obj.script and not obj.script[1] then
		obj.script = { obj.script }
	end
	obj:call('init')
end

local function finalizeRemoved(tree)
	for i=#tree.removed,1,-1 do
		tree.removed[i]:call('final')
		tree.removed[i] = nil
	end
end

function _moveChild(obj, oldParent, iChild, newParent)
	oldParent.children[iChild] = nil
	if not newParent.children then newParent.children = {} end
	table.insert(newParent.children, obj)
	obj.parent = newParent
end

-- Actually swap obj between new and old parents' child lists.
local function finishReparenting(tree)
	for key,v in pairs(tree.reparents) do
		_moveChild(unpack(v))
		tree.reparents[key] = nil
	end
end

local function finalizeAndReparent(tree)
	finalizeRemoved(tree)
	finishReparenting(tree)
end

local function _update(objects, dt)
	for _,obj in pairs(objects) do
		if not obj.paused then
			if obj.children then
				_update(obj.children, dt)
			end
			obj:call('update', dt)
		end
	end
end

function SceneTree.update(self, dt)
	finalizeAndReparent(self)
	_update(self.children, dt, self.draw_order)
	finalizeAndReparent(self)
end

local function collectVisible(tree, objects)
	local draw_order = tree.draw_order
	for _,obj in pairs(objects) do
		if obj.visible then
			obj:updateTransform()
			draw_order:saveCurrentLayer()
			draw_order:addObject(obj)
			if obj.children then
				collectVisible(tree, obj.children)
			end
			draw_order:restoreCurrentLayer()
		end
	end
end

function SceneTree.draw(self, groups)
	collectVisible(self, self.children)
	self.draw_order:draw(groups)
	self.draw_order:clear()
end

-- This sets all the transforms, which seems like a waste,
-- because we're probably calling this from `update` which will
-- immediately do it all over again.  But an object's `init`
-- method may refer to them, so they need to be set now.
function SceneTree.add(self, obj, parent)
	parent = parent or self
	if not parent.children then parent.children = {} end
	local i = 1 + #parent.children
	parent.children[i] = obj
	initChild(self, obj, parent, i)
end

-- Take an object out of the tree. If, on `update`, you remove an
-- ancestor, it and some of its descendants (the not-yet-processed
-- siblings) may still get `update`d.
function SceneTree.remove(self, obj)
	local parent = obj.parent
	for i,c in pairs(parent.children) do
		if c == obj then
			parent.children[i] = nil
			break
		end
	end
	table.insert(self.removed, obj)
	self.paths[obj.path] = nil
end

-- By default, doesn't re-parent obj until the next pre- or
-- post-update. The now parameter says to do it immediately. The
-- keepWorld argument says to keep the world position (only
-- has an effect for objects with TRANSFORM_REGULAR).
function SceneTree.setParent(self, obj, parent, keepWorld, now)
	parent = parent or self
	keepWorld = keepWorld or false
	if parent == obj.parent then
		print('Tried to set_parent to current parent: ' .. parent.path)
		return
	end
	for k,c in pairs(obj.parent.children) do
		if c == obj then
			if now then
				_moveChild(obj, obj.parent, k, parent)
			else
				table.insert(self.reparents, {obj, obj.parent, k, parent})
				obj.parent = parent
			end
			if obj.updateTransform == Object.TRANSFORM_REGULAR then
				if keepWorld then
					local m = {}
					M.xM(obj._to_world, M.invert(newParent._to_world, m), m)
					obj.pos.x, obj.pos.y = m.x, m.y
					obj.th, obj.sx, obj.sy, obj.kx, obj.ky = M.parameters(m)
				else
					obj:updateTransform()
				end
			end
			return
		end
	end
	error('scene.setParent - could not find child "' .. obj.path .. '" in parent ("' .. parent.path .. '") child list.')
end

-- TODO - make an object-based relative-path version?
function SceneTree.get(self, path)
	return self.paths[path]
end

return SceneTree
