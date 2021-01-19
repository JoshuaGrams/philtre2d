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

local function updatePath(self, obj, basePath)
	local uniqueNamePath = basePath .. obj.name
	if obj.path ~= uniqueNamePath then
		self.paths[obj.path] = nil
		obj.path = uniqueNamePath .. obj._index
		self.paths[obj.path] = obj
	end
end

function Tree.swap(self, parent, i1, i2)
	local children = parent.children
	local c1, c2 = children[i1], children[i2]
	children[i1], children[i2] = c2, c1
	local basePath = parent.path .. self.pathSeparator
	if c1 then
		c1._index = i2
		updatePath(self, c1, basePath)
	end
	if c2 then
		c2._index = i1
		updatePath(self, c2, basePath)
	end
	-- Can swap out the last child with nil, so we should double-check `maxn`.
	while not children[children.maxn] and children.maxn > 0 do
		children.maxn = children.maxn - 1
	end
end

function Tree.add(self, obj, parent, atIndex)
	if atIndex then  assert(atIndex > 0, 'Tree.add: atIndex must be greater than 0.')  end
	if parent and parent ~= self then
		parent.children = parent.children or { maxn = 0 }
	else
		parent = self -- No parent specified, add at tree root.
	end

	local children = parent.children
	local index = atIndex or #children + 1 -- Reminder: # doesn't get the -first- nil, it just gets -some- nil.

	if atIndex and children[atIndex] then -- Inserting into a filled space, need to shift children up to the next gap.
		local basePath = parent.path .. self.pathSeparator
		local maxn = children.maxn
		for i=atIndex,maxn do
			local child = children[i]
			if child then -- Just update the index and path, the table.insert of the new child will do the actual shifting.
				child._index = i+1
				updatePath(self, child, basePath)
				if i == maxn then  children.maxn = maxn + 1  end
			else -- Found a nil element before we hit maxn.
				table.remove(children, i) -- Remove the nil element so it's "filled" when table.insert shifts everything up.
				break -- Stop at the first nil.
			end
		end
	end

	children.maxn = math.max(children.maxn, index)
	table.insert(children, index, obj)

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
