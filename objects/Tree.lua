local base = (...):gsub('objects%.Tree$', '')
local M = require(base .. 'modules.matrix')
local Object = require(base .. 'objects.Object')

local Tree = Object:extend()

Tree.pathSeparator = '/'

function Tree.__tostring(self)
	return 'Tree: ' .. self.id
end

function Tree.set(self)
	self._to_world = M.identity
	self._to_local = M.identity
	self.pos = {x=0, y=0}
	self.children = { maxn = 0 }
	self.path = ''
	self.paths = {}
end

local function initObject(tree, obj, parent, index, objList)
	obj.tree = tree -- So object classes can use the tree without globals or dependencies.
	obj.parent = parent
	obj.name = obj.name or tostring(index)
	obj._index = index

	local path = parent.path .. tree.pathSeparator .. obj.name
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
			if child then  initObject(tree, child, obj, i, objList)  end -- May be holes in the child list.
		end
	end
	table.insert(objList, obj) -- Bottom-up order.
end

function Tree.add(self, obj, parent)
	if parent and parent ~= self then
		parent.children = parent.children or { maxn = 0 }
	else
		parent = self -- No parent specified, add at tree root.
	end

	local index = #parent.children + 1
	parent.children.maxn = math.max(parent.children.maxn, index)
	parent.children[index] = obj

	local objList = {}
	initObject(self, obj, parent, index, objList)
	return objList
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

function Tree.remove(self, obj)
	local childList = obj.parent.children
	childList[obj._index] = nil
	while not childList[childList.maxn] and childList.maxn > 0 do
		childList.maxn = childList.maxn - 1
	end
	obj.parent = nil -- Don't unset parents on descendants, leave the branch intact.

	finalizeObject(self, obj) -- Don't bother assembling an object list, it's too late for SceneTree to use it.
end

function Tree.get(self, path)
	return self.paths[path]
end

return Tree
