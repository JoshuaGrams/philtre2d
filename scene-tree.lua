local base = (...):gsub('[^%.]+$', '')
local M = require(base .. 'matrix')
local Object = require(base .. 'Object')
local DrawOrder = require(base .. 'draw-order')

local SceneTree = Object:extend()

function SceneTree.__tostring(self)
	return 'SceneTree: ' .. self.id
end

function SceneTree.set(self, groups, default)
	groups = groups or {'default'}
	default = default or 'default'
	self.draw_order = DrawOrder(groups, default)
	self._to_world = M.identity
	self._to_local = M.identity
	self.pos = {x=0, y=0}
	self.children = {}
	self.path = ''
	self.paths = {}
	self.removed = {}    -- finalize after next update
	self.reparents = {}  -- to complete after next update
	self.compact = {}    -- renumber children after next update
end

local deletedMarker = Object()
deletedMarker.name = "deletedMarker" -- So you have some way tell what it is.
deletedMarker.path = {} -- Prevents crash if you remove a branch with deletedMarkers in it.

local function initChild(tree, obj, parent, index)
	-- Prevent duplicate init
	if obj.parent == parent then return end

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
		for i,child in pairs(obj.children) do
			initChild(tree, child, obj, i)
		end
	end

	if obj.script and not obj.script[1] then
		obj.script = { obj.script }
	end
	obj:call('init')
end

local function finalizeRemoved(objects)
	for obj,_ in pairs(objects) do
		objects[obj] = nil
		obj:callRecursive('final')
	end
end

function _moveChild(obj, oldParent, iChild, newParent)
	oldParent.children[iChild] = deletedMarker
	obj.tree.compact[oldParent] = true
	if not newParent.children then newParent.children = {} end
	table.insert(newParent.children, obj)
end

-- Actually swap obj between new and old parents' child lists.
local function finishReparenting(moves)
	for key,v in pairs(moves) do
		_moveChild(unpack(v))
		moves[key] = nil
	end
end

local function compact(list, skip)
	local j = 1
	for i,v in ipairs(list) do
		if v == skip then
			list[i] = nil
		else
			if i ~= j then list[i], list[j] = nil, v end
			j = j + 1
		end
	end
end

local function compactChildren(objects)
	for obj,_ in pairs(objects) do
		local n = #obj.children
		compact(obj.children, deletedMarker)
		objects[obj] = nil
	end
end

local function finalizeAndReparent(tree)
	if next(tree.removed) then
		finalizeRemoved(tree.removed)
	end
	if next(tree.reparents) then
		finishReparenting(tree.reparents)
	end
	if next(tree.compact) then
		compactChildren(tree.compact)
	end
end

local function _update(objects, dt)
	for _,obj in pairs(objects) do
		if obj.timeScale ~= 0 then
			if obj.timeScale then  dt = dt * obj.timeScale  end
			if obj.children then
				_update(obj.children, dt)
			end
			obj:call('update', dt)
		end
	end
end

function SceneTree.update(self, dt)
	_update(self.children, dt)
	finalizeAndReparent(self)
end

function SceneTree.updateTransforms(tree, objects)
	for _,obj in pairs(objects or tree.children) do
		if obj.visible then
			obj:updateTransform()
			if obj.children then
				tree:updateTransforms(obj.children)
			end
		end
	end
end

function SceneTree.draw(self, groups)
	finalizeAndReparent(self)
	self:updateTransforms()
	self.draw_order:draw(groups)
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

	-- Add to draw-order - after whole branch is init so visibility inheritance happens easily.
	self.draw_order:addObject(obj)
end

local function recursiveRemovePaths(tree, obj)
	if obj.children then
		for i,child in ipairs(obj.children) do
			recursiveRemovePaths(tree, child)
		end
	end
	tree.paths[obj.path] = nil
end

-- Take an object out of the tree. If, on `update`, you remove an
-- ancestor, it and some of its descendants (the not-yet-processed
-- siblings) may still get `update`d.
function SceneTree.remove(self, obj)
	local parent = obj.parent
	if not parent then  return  end -- obj is not in the tree or is a deletedMarker.

	self.draw_order:removeObject(obj) -- before nullifying any parent references so we can find the right layer.

	for i,child in ipairs(parent.children) do
		if child == obj then
			parent.children[i] = deletedMarker
			self.compact[parent] = true
			obj.parent = nil
			break
		end
	end
	self.removed[obj] = true
	self.paths[obj.path] = nil
	recursiveRemovePaths(self, obj)

end

-- By default, doesn't re-parent obj until after the next update.
-- The now parameter says to do it immediately. The keepWorld
-- argument says to keep the world position the same (only has an
-- effect for objects with TRANSFORM_REGULAR).
function SceneTree.setParent(self, obj, parent, keepWorld, now)
	parent = parent or self
	keepWorld = keepWorld or false
	if parent == obj.parent then
		print('Tried to set_parent to current parent: ' .. parent.path)
		return
	end
	for k,c in ipairs(obj.parent.children) do
		if c == obj then
			self.draw_order:removeObject(obj) -- before parent changes - remove from old layers
			if now then
				_moveChild(obj, obj.parent, k, parent)
			else
				table.insert(self.reparents, {obj, obj.parent, k, parent})
			end
			self.compact[obj.parent] = true
			obj.parent = parent
			self.draw_order:addObject(obj) -- after parent changes - add to new layers
			if obj.updateTransform == Object.TRANSFORM_REGULAR then
				if keepWorld then
					local m = {}
					M.xM(obj._to_world, M.invert(parent._to_world, m), m)
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
