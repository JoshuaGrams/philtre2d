local base = (...):gsub('objects%.SceneTree$', '')
local Tree = require(base .. 'objects.Tree')
local DrawOrder = require(base .. 'render.draw-order')
local matrix = require(base .. 'core.matrix')
local OBJECT_TRANSFORM_REGULAR = require(base .. 'objects.Object').TRANSFORM_REGULAR

local SceneTree = Tree:extend()

function SceneTree.set(self, groups, default)
	SceneTree.super.set(self)
	default = default or 'default'
	groups = groups or { default }
	self.drawOrder = DrawOrder(groups, default)
end

local function isObject(obj) -- This should be all we require to use an object in the tree.
	return type(obj) == "table" and obj.call and obj.updateTransform
	-- NOTE: Though obj.visible must be truthy for the object to be drawn.
end

local function listDescendants(children, isTopDown, list, j)
	list = list or {}
	j = j or 0 -- Managing our own index is 10-15x faster than using table.insert.
	for i=1,children.maxn do
		local obj = children[i]
		if obj then
			if isTopDown then  j = j + 1;  list[j] = obj  end
			if obj.children then  list, j = listDescendants(obj.children, isTopDown, list, j)  end
			if not isTopDown then  j = j + 1;  list[j] = obj  end
		end
	end
	return list, j
end

-- `Parent` can be the tree or any object.
function SceneTree.getObjList(parent, isTopDown)
	if not parent.children then  return { parent }  end

	local list = { isTopDown and parent or nil }

	listDescendants(parent.children, isTopDown, list, isTopDown and 1) -- Be sure to start with correct index.
	if not isTopDown then  table.insert(list, parent)  end
	return list
end

function SceneTree.add(self, obj, parent, atIndex)
	assert(isObject(obj), 'SceneTree.add: obj: '..tostring(obj)..' is not an object.')
	assert(not obj.path, 'SceneTree.add: obj: '..tostring(obj)..' is already in the tree.')
	if atIndex then  assert(atIndex % 1 == 0, 'SceneTree.add: atIndex: '..tostring(atIndex)..' is not an integer.')  end
	parent = parent or self
	if parent ~= self then
		assert(isObject(parent), 'SceneTree.add: parent: '..tostring(parent)..' is not an object.')
	end

	local objList = SceneTree.super.add(self, obj, parent, atIndex)
	self.drawOrder:addObject(obj)
	for i=1,#objList do
		local obj = objList[i]
		if obj.path then -- Is still in tree.
			obj:call('init')
		end
	end
	return obj
end

function SceneTree.remove(self, obj)
	assert(isObject(obj), 'SceneTree.remove: obj: '..tostring(obj)..'is not an object.')
	assert(obj.path, 'SceneTree.remove: obj: '..tostring(obj)..'is not in the tree.')

	SceneTree.callRecursive(obj, false, 'final')
	self.drawOrder:removeObject(obj)
	SceneTree.super.remove(self, obj)
end

function SceneTree.setParent(self, obj, parent, keepWorldTransform)
	assert(isObject(obj), 'SceneTree.add: obj: '..tostring(obj)..' is not an object.')
	parent = parent or self
	if parent ~= self then
		assert(isObject(parent), 'SceneTree.add: parent: '..tostring(parent)..' is not an object.')
	end
	if keepWorldTransform and obj.updateTransform == OBJECT_TRANSFORM_REGULAR then
		local m = {}
		matrix.xM(obj._toWorld, matrix.invert(parent._toWorld, m), m)
		obj.pos.x, obj.pos.y = m.x, m.y
		obj.angle, obj.sx, obj.sy, obj.kx, obj.ky = matrix.parameters(m)
	end
	self.drawOrder:removeObject(obj)
	SceneTree.super.remove(self, obj)
	SceneTree.super.add(self, obj, parent)
	self.drawOrder:addObject(obj)
end

local function locked_add()  error("SceneTree.add: Can't modify tree while it is locked.")  end
local function locked_remove()  error("SceneTree.remove: Can't modify tree while it is locked.")  end
local function locked_swap()  error("SceneTree.swap: Can't modify tree while it is locked.")  end
local function locked_setParent()  error("SceneTree.setParent: Can't modify tree while it is locked.")  end

function SceneTree.lock(self)
	self.add, self.remove, self.swap, self.setParent = locked_add, locked_remove, locked_swap, locked_setParent
end

function SceneTree.unlock(self)
	self.add, self.remove, self.swap, self.setParent = nil, nil, nil, nil -- Go back to Tree methods in metatable.
end

-- By definition, transforms must be updated in top-down tree order, parent -> child.
-- Invisible or paused objects' transforms are still updated.
local function updateTransforms(children)
	for i=1,children.maxn do
		local obj = children[i]
		if obj then
			obj:updateTransform()
			if obj.children then  updateTransforms(obj.children)  end
		end
	end
end

function SceneTree.updateTransforms(self, obj)
	self:lock()
	if obj then  obj:updateTransform()  end
	updateTransforms((obj or self).children)
	self:unlock()
end

-- Can freely modify the tree during this call.
function SceneTree.callRecursive(self, isTopDown, callbackName, ...)
	local list = SceneTree.getObjList(self, isTopDown)
	for i=1,#list do
		local obj = list[i]
		if obj.path then -- Is still in tree.
			obj:call(callbackName, ...)
		end
	end
end

-- Same as Object.call - Needed for callRecursive to work on the SceneTree itself.
function SceneTree.call(self, fnName, ...)
	if self[fnName] then  self[fnName](self, ...)  end
	if self.scripts then
		for _,script in ipairs(self.scripts) do
			if script[fnName] then  script[fnName](self, ...)  end
		end
	end
end

-- Recurse down the tree storing a flat list of objects and each object's effective dt.
local function fillUpdateLists(objects, dt, objList, dtList, j)
	j = j or 0
	for i=1,objects.maxn do
		local obj = objects[i]
		if obj and obj.timeScale ~= 0 then
			local _dt = dt
			if obj.timeScale then  _dt = dt * obj.timeScale  end
			if obj.children then  j = fillUpdateLists(obj.children, _dt, objList, dtList, j)  end
			j = j + 1
			objList[j] = obj
			dtList[j] = _dt
		end
	end
	return j
end

function SceneTree.update(self, dt)
	local objList, dtList = {}, {}
	local count = fillUpdateLists(self.children, dt, objList, dtList)
	for i=1,count do
		local obj = objList[i]
		if obj.path then
			obj:call('update', dtList[i])
		end
	end
end

function SceneTree.draw(self, groups)
	self.drawOrder:draw(groups)
end

return SceneTree
