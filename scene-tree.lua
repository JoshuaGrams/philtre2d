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
	self.movedFrom = {}  -- Maps child -> old parent.
end

local function initChild(tree, obj, parent, index)
	-- Prevent duplicate init
	if obj.parent == parent then return end

	obj.name = obj.name or tostring(index)
	local basePath = parent.path .. '/' .. obj.name
	obj.path = basePath
	while tree.paths[obj.path] do
		obj.path = basePath .. index
		index = index + 1
		if index > #parent.children * 3/2 then index = 1 end
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

local function compactChildren(parent, movedFrom)
	local children = parent.children
	-- Loop over *all* current children.
	local j = 1  -- new index
	for i,obj in ipairs(children) do
		if movedFrom[obj] == parent then
			-- Remove it, then finalize or insert into new parent.
			movedFrom[obj], children[i] = nil, nil
			if obj.parent then
				obj.parent.children = obj.parent.children or {}
				table.insert(obj.parent.children, obj)
			else
				obj:callRecursive('final')
			end
		else
			-- Not removed: slide it up to fill any gap.
			if i ~= j then
				children[i], children[j] = nil, obj
			end
			j = j + 1
		end
	end
end

local function finalizeAndReparent(tree)
	for _,parent in pairs(tree.movedFrom) do
		compactChildren(parent, tree.movedFrom)
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

local function find(list, value)
	for i,v in ipairs(list) do
		if v == value then return i end
	end
end

-- Take an object out of the tree. If, on `update`, you remove an
-- ancestor, it and some of its descendants (the not-yet-processed
-- siblings) may still get `update`d.
function SceneTree.remove(self, obj)
	if not self.paths[obj.path] then  return  end -- obj is not in the tree.
	local parent = obj.parent or self.movedFrom[obj]
	if not (parent and find(parent.children, obj)) then return  end -- obj is not in the tree.

	self.draw_order:removeObject(obj) -- before nullifying any parent references so we can find the right layer.

	self.movedFrom[obj] = self.movedFrom[obj] or obj.parent
	obj.parent = nil
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
	local i = find(obj.parent.children, obj)
	if not i then
		error('scene.setParent - could not find child "' .. obj.path .. '" in parent ("' .. parent.path .. '") child list.')
	end
	self.draw_order:removeObject(obj) -- before parent changes - remove from old layers
	if now then
		table.remove(obj.parent.children, i)
	else
		self.movedFrom[obj] = self.movedFrom[obj] or obj.parent
	end
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
end

-- TODO - make an object-based relative-path version?
function SceneTree.get(self, path)
	return self.paths[path]
end

return SceneTree
