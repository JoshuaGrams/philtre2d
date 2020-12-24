local base = (...):gsub('[^%.]+$', '')
local M = require(base .. 'matrix')
local Object = require(base .. 'Object')
local DrawOrder = require(base .. 'draw-order')

local SceneTree = Object:extend()

local PATH_SEPARATOR = '/'

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
	self.children = { maxn = 0 }
	self.path = ''
	self.paths = {}
end

local function initObject(tree, obj, parent, index)
	obj.tree = tree -- So object classes can use the tree without globals or dependencies.
	obj.parent = parent
	obj.name = obj.name or tostring(index)
	obj._index = index

	local path = parent.path .. PATH_SEPARATOR .. obj.name
	if tree.paths[path] then -- Append index if identical path exists.
		path = path .. index
	end
	obj.path = path
	tree.paths[path] = obj

	if obj.script and not obj.script[1] then
		obj.script = { obj.script }
	end

	if obj.children then
		obj.children.maxn = obj.children.maxn or #obj.children
		for i=1,obj.children.maxn do
			local child = obj.children[i]
			if child then  initObject(tree, child, obj, i)  end -- May be holes in the child list.
		end
	end
end

function SceneTree.add(self, obj, parent, skipCall)
	assert(obj.is and obj:is(Object), 'SceneTree.add: obj: '..tostring(obj)..' is not an Object.')
	assert(not obj.path, 'SceneTree.add: obj: '..tostring(obj)..' is already in the tree.')
	if parent and parent ~= self then
		assert(parent.is and parent:is(Object), 'SceneTree.add: parent: '..tostring(parent)..' is not an Object.')
		parent.children = parent.children or { maxn = 0 }
	else
		parent = self -- No parent specified, add at tree root.
	end

	local index = #parent.children + 1
	parent.children.maxn = math.max(parent.children.maxn, index)
	parent.children[index] = obj

	initObject(self, obj, parent, index)

	self.draw_order:addObject(obj)

	if not skipCall then  SceneTree.__call(obj, 'init')  end
end

local function finalizeObject(tree, obj)
	tree.paths[obj.path] = nil
	obj.path = nil
	obj.tree = nil
	if obj.children then
		for i=1,obj.children.maxn do
			local child = obj.children[i]
			if child then  finalizeObject(tree, child)  end
		end
	end
end

function SceneTree.remove(self, obj, skipCall)
	assert(obj:is(Object), 'SceneTree.remove: obj: '..tostring(obj)..'is not an Object.')
	assert(obj.path, 'SceneTree.remove: obj: '..tostring(obj)..'is not in the tree.')

	if not skipCall then  SceneTree.__call(obj, 'final')  end

	self.draw_order:removeObject(obj)

	local childList = obj.parent.children
	childList[obj._index] = nil
	while not childList[childList.maxn] and childList.maxn > 0 do
		childList.maxn = childList.maxn - 1
	end
	obj.parent = nil -- Don't unset parents on descendants, leave the branch intact.

	finalizeObject(self, obj)
end

function SceneTree.setParent(self, obj, parent) -- TODO: keepWorldTransform
	SceneTree.remove(self, obj, true)
	SceneTree.add(self, obj, parent, true)
end

local function locked_add()  error("SceneTree.add: Can't modify tree during updateTransforms step.")  end
local function locked_remove()  error("SceneTree.remove: Can't modify tree during updateTransforms step.")  end
local function locked_setParent()  error("SceneTree.setParent: Can't modify tree during updateTransforms step.")  end

function SceneTree.lock(self)
	self.add, self.remove, self.setParent = locked_add, locked_remove, locked_setParent
end

function SceneTree.unlock(self)
	self.add, self.remove, self.setParent = nil, nil, nil -- Go back to Tree methods in metatable.
end

-- By definition, transforms must be updated in top-down tree order, parent -> child.
-- Invisible objects' transforms are still updated.
local function updateTransforms(children)
	for i=1,children.maxn do
		local obj = children[i]
		if obj then
			obj:updateTransform()
			if obj.children then  updateTransforms(obj.children)  end
		end
	end
end

function SceneTree.updateTransforms(self)
	SceneTree.lock(self)
	updateTransforms(self.children)
	SceneTree.unlock(self)
end

local function fillList(list, children, topDown)
	for i=1,children.maxn do
		local obj = children[i]
		if obj then
			if topDown then  table.insert(list, obj)  end
			if obj.children then  fillList(list, obj.children, topDown)  end
			if not topDown then  table.insert(list, obj)  end
		end
	end
end

-- `Parent` can be the tree or any object.
function SceneTree.getObjList(parent, topDown)
	if not parent.children then  return { parent }  end
	local list = { topDown and parent or nil }
	fillList(list, parent.children, topDown)
	if not topDown then  table.insert(list, parent)  end
	return list
end

function SceneTree.__call(self, callbackName, topDown, ...)
	local list = SceneTree.getObjList(self, topDown)
	for i=1,#list do
		local obj = list[i]
		if obj.path then -- Is still in tree.
			obj:call(callbackName, ...)
		end
	end
end

local function fillUpdateLists(objects, dt, objList, dtList)
	for i=1,objects.maxn do
		local obj = objects[i]
		if obj and obj.timeScale ~= 0 then
			if obj.timeScale then  dt = dt * obj.timeScale  end
			if obj.children then  fillUpdateLists(obj.children, dt, objList, dtList)  end
			table.insert(objList, obj)
			table.insert(dtList, dt)
		end
	end
end

function SceneTree.update(self, dt)
	local objList, dtList = {}, {}
	fillUpdateLists(self.children, dt, objList, dtList)
	for i=1,#objList do
		local obj = objList[i]
		if obj.path then
			obj:call('update', dtList[i])
		end
	end
end

function SceneTree.draw(self, groups)
	SceneTree.updateTransforms(self)
	self.draw_order:draw(groups)
end

function SceneTree.get(self, path)
	return self.paths[path]
end

return SceneTree
