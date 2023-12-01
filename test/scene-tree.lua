local base = (...):gsub('[^%.]+.[^%.]+$', '')
local T = require 'lib.simple-test'

local SceneTree = require(base .. 'objects.SceneTree')
local Object = require(base .. 'objects.Object')

local function mod(obj, props)
	for name,prop in pairs(props) do
		obj[name] = prop
	end
	return obj
end

local function obj_call(self, fnName, ...)
	if self[fnName] then  self[fnName](self, ...)  end
end
local function obj_updateTransform(self)  end
local function Dummy()
	return { call = obj_call, updateTransform = obj_updateTransform }
end

return {
	'SceneTree/Object',
	setup = function() return SceneTree() end,

	-- Check for duplicate init when adding sibling on init.
	function(scene)
		local initOrder = {}
		local function init(obj)  table.insert(initOrder, obj.name)  end

		local a = mod(Object(0, 0), {name = 'a'})
		local b = mod(Object(10, 0), {name = 'b', init = init})
		local c = mod(Object(20, 0), {name = 'c', init = init})
		local container = mod(Object(0, 0), {name = 'Parent', init = init, children = {a, b}})

		a.init = function(obj)
			init(obj)
			scene:add(c, obj.parent)
		end

		scene:add(container)
		T.is(table.concat(initOrder, ' '), 'a c b Parent',
			'Adding a sibling in init should not cause objects to be initialized more than once.')
	end,

	-- Does this cause duplicate paths?
	function(scene)
		local obj = {}
		for i=1,4 do table.insert(obj, Object(10*(i-1), 0)) end
		scene:add(obj[1])  -- /Object
		scene:add(obj[2])  -- /Object2
		scene:add(obj[3])  -- /Object3
		-- Remove the first one that has a number attached.
		scene:remove(obj[2])
		-- Compact the child list.
		scene:update(1/60)
		scene:add(obj[4])  -- /Object4?
		scene:add(obj[2])  -- /Object5?
		for i=1,#obj-1 do
			for j=i+1,#obj do
				local ok = obj[i].path ~= obj[j].path
				local msg = 'obj['..i..'] and obj['..j..'] have different paths.'
				T.areOK(ok, obj[i].path, obj[j].path, msg)
			end
		end
	end,

	function(scene)
		local objDt
		local function upd(self, dt)  objDt = dt  end
		scene:add(mod(Object(), {update = upd}))
		local sentDt = 1/60
		scene:update(sentDt)
		T.is(objDt, sentDt, 'Object in tree got update with correct dt.')
	end,

	function(scene)
		local initOrder = {}
		local function init(obj)  table.insert(initOrder, obj.name)  end

		local isErr, result
		local function delParent(obj)
			table.insert(initOrder, obj.name)
			isErr, result = pcall(obj.tree.remove, obj.tree, obj.parent)
		end

		local a = mod(Object(0, 0), {name = 'a', init = init})
		local b = mod(Object(10, 0), {name = 'b', init = delParent})
		local c = mod(Object(20, 0), {name = 'c', init = init})
		local container = mod(Object(0, 0), {name = 'Parent', init = init, children = {a, b, c}})

		scene:add(container)
		T.is(result, nil, 'Child can delete its own parent on init.')
	end,

	function(scene)
		local p = Object()
		local o1, o3 = Object(), Object()
		p.children = { o1, nil, o3 }
		scene:add(p)
		scene:swap(p, 1, 3)
		T.ok(p.children[1] == o3 and p.children[3] == o1, 'Tree.swap: the children got swapped in the child list.')

		scene:swap(p, 3, 2) -- Swap child[3] into nil space at [2]
		T.is(p.children.maxn, 2, 'Swapping last child with nil shifts children.maxn.')
	end,

	function(scene)
		-- Swap object to a slot past the end of the child list.
		local o = Object()
		scene:add(o)
		scene:swap(scene, 1, 2)
		T.is(scene.children.maxn, 2, 'Swapping child to a slot past the end of the child list works.')
	end,

	function(scene)
		local p, o = Object(), Object()
		scene:add(p)
		local isSuccess, result = pcall(scene.add, scene, o, p, 0)
		T.ok(not isSuccess, 'Trying to insert a child at index 0 causes an error.')
		-- Also ensures that SceneTree.add passes the `atIndex` arg on to Tree.add.
	end,

	function(scene)
		local p = Object()
		local o1, o2, o3 = Object(), Object(), Object()
		p.children = { o1, nil, o3 }
		local ch = p.children
		scene:add(p)

		scene:add(o2, p, 2)
		T.is(ch[2], o2, 'Object inserted into middle gap in child list')
		T.ok(ch[1] == o1 and ch[3] == o3, '   Objects on either side of gap are unchanged')
		local indicesCorrect = ch[1]._index == 1 and ch[2]._index == 2 and ch[3]._index == 3
		T.ok(indicesCorrect, '   Indices of all children are correct.')
	end,

	function(scene)
		local p = Object()
		local o1, o2, o3 = Object(), Object(), Object()
		p.children = { o1, nil, o3 }
		scene:add(p)
		scene:add(o2, p, 10)
		T.is(p.children.maxn, 10, 'Inserting a child past maxn updates maxn correctly.')

		scene:swap(p, 10, 2)
		T.is(p.children.maxn, 3, 'Swapping that last child with nil shrinks maxn again correctly.')
	end,

	function(scene)
		local p = Object()
		local child = {}
		p.children = child
		for i=1,10 do  child[i] = Object()  end

		child[4] = nil -- Add a gap at index 4.
		scene:add(p)

		local maxn = child.maxn

		-- Insert child at index 2 (should push 2 & 3 up to 3 & 4, filling the gap).
		local testO = Object()
		local o2, o3, o5 = child[2], child[3], child[5]
		scene:add(testO, p, 2)

		-- Have to check the child AFTER the gap too, to make sure the gap was filled.
		local isCorrect = child[2] == testO and child[3] == o2 and child[4] == o3 and child[5] == o5
		T.ok(isCorrect, 'Inserting before a gap shifts up children and fills the gap.')

		T.is(p.children.maxn, maxn, '   Maxn is unchanged.')

		-- Double-check all child indices.
		for i=1,child.maxn do
			local c = child[i]
			if c then  T.is(c._index, i, '   Index of child['..i..'] is correct.')  end
		end
	end,

	function(scene)
		scene:add(Object())
		scene:add(Object())
		local IS_TOPDOWN = true
		local list = scene:getObjList(IS_TOPDOWN)
		T.is(#list, 3, "getObjList returns a list that's the correct length")
		T.is(list[1], scene, "getObjList - first in topdown list is the parent.")

		local uplist = scene:getObjList(not IS_TOPDOWN)
		T.is(#uplist, 3, "getObjList bottom-up returns a list that's the correct length")
		T.ok(uplist[1] ~= scene, "getObjList bottom-up - first in list is NOT the parent.")
		T.is(uplist[3], scene, "getObjList bottom-up - last in list is the parent.")
	end,

	function(scene)
		local success, errMsg = pcall(scene.callRecursive, scene, "callback name")
		T.ok(success, "SceneTree.callRecursive works on the tree itself.")
		if not success then  print(errMsg)  end
	end,

	function(scene) -- Check scene.updateTransforms().
		local pathsOfUpdated = ""
		local function ut(self)
			Object.updateTransform(self)
			pathsOfUpdated = pathsOfUpdated .. self.path .. ", "
		end
		local function Obj()
			local o = Object()
			o.updateTransform = ut
			return o
		end
		scene:add(Obj())
		local p = scene:add(Obj())
		scene:add(Obj(), p)
		scene:add(Obj())
		pathsOfUpdated = "" -- Objects' transforms are updated when they are added.
		scene:updateTransforms()
		-- Top-down order.
		T.is(pathsOfUpdated, "/Object, /Object2, /Object2/Object, /Object3, ", "scene:updateTransforms() updates the transforms of all descendants.")
		pathsOfUpdated = ""
		scene:updateTransforms(p)
		T.is(pathsOfUpdated, "/Object2, /Object2/Object, ", "scene:updateTransforms(obj) updates 'obj' and its children.")
	end,

	-- ##########  RUN DUPLICATE TESTS WITH DUMMY OBJECT  ##########
	'SceneTree with minimal Dummy object',

	function(scene)
		local success, errMsg = pcall(scene.add, scene, Dummy())
		T.ok(success, "SceneTree.add works with Dummy object.")
		if not success then  print(errMsg)  end
	end,

	function(scene)
		local obj = scene:add(Object())
		T.ok(type(obj.name) == "string", "Dummy object is given a string name upon being added.")
	end,

	-- Check for duplicate init when adding sibling on init.
	function(scene)
		local initOrder = {}
		local function init(obj)  table.insert(initOrder, obj.name)  end

		local a = mod(Dummy(0, 0), {name = 'a'})
		local b = mod(Dummy(10, 0), {name = 'b', init = init})
		local c = mod(Dummy(20, 0), {name = 'c', init = init})
		local container = mod(Dummy(0, 0), {name = 'Parent', init = init, children = {a, b}})

		a.init = function(obj)
			init(obj)
			scene:add(c, obj.parent)
		end

		scene:add(container)
		T.is(table.concat(initOrder, ' '), 'a c b Parent',
			'Adding a sibling in init should not cause objects to be initialized more than once.')
	end,

	-- Does this cause duplicate paths?
	function(scene)
		local obj = {}
		for i=1,4 do table.insert(obj, Dummy(10*(i-1), 0)) end
		scene:add(obj[1])
		scene:add(obj[2])
		scene:add(obj[3])
		-- Remove the first one that has a number attached.
		scene:remove(obj[2])
		-- Compact the child list.
		scene:update(1/60)
		scene:add(obj[4])
		scene:add(obj[2])
		for i=1,#obj-1 do
			for j=i+1,#obj do
				local ok = obj[i].path ~= obj[j].path
				local msg = 'obj['..i..'] and obj['..j..'] have different paths.'
				T.areOK(ok, obj[i].path, obj[j].path, msg)
			end
		end
	end,

	function(scene)
		local objDt
		local function upd(self, dt)  objDt = dt  end
		scene:add(mod(Dummy(), {update = upd}))
		local sentDt = 1/60
		scene:update(sentDt)
		T.is(objDt, sentDt, 'Object in tree got update with correct dt.')
	end,

	function(scene)
		local initOrder = {}
		local function init(obj)  table.insert(initOrder, obj.name)  end

		local isErr, result
		local function delParent(obj)
			table.insert(initOrder, obj.name)
			isErr, result = pcall(obj.tree.remove, obj.tree, obj.parent)
		end

		local a = mod(Dummy(0, 0), {name = 'a', init = init})
		local b = mod(Dummy(10, 0), {name = 'b', init = delParent})
		local c = mod(Dummy(20, 0), {name = 'c', init = init})
		local container = mod(Dummy(0, 0), {name = 'Parent', init = init, children = {a, b, c}})

		scene:add(container)
		T.is(result, nil, 'Child can delete its own parent on init.')
	end,

	function(scene)
		local p = Dummy()
		local o1, o3 = Dummy(), Dummy()
		p.children = { o1, nil, o3 }
		scene:add(p)
		scene:swap(p, 1, 3)
		T.ok(p.children[1] == o3 and p.children[3] == o1, 'Tree.swap: the children got swapped in the child list.')

		scene:swap(p, 3, 2) -- Swap child[3] into nil space at [2]
		T.is(p.children.maxn, 2, 'Swapping last child with nil shifts children.maxn.')
	end,

	function(scene)
		-- Swap object to a slot past the end of the child list.
		local o = Dummy()
		scene:add(o)
		scene:swap(scene, 1, 2)
		T.is(scene.children.maxn, 2, 'Swapping child to a slot past the end of the child list works.')
	end,

	function(scene)
		local p, o = Dummy(), Dummy()
		scene:add(p)
		local isSuccess, result = pcall(scene.add, scene, o, p, 0)
		T.ok(not isSuccess, 'Trying to insert a child at index 0 causes an error.')
		-- Also ensures that SceneTree.add passes the `atIndex` arg on to Tree.add.
	end,

	function(scene)
		local p = Dummy()
		local o1, o2, o3 = Dummy(), Dummy(), Dummy()
		p.children = { o1, nil, o3 }
		local ch = p.children
		scene:add(p)

		scene:add(o2, p, 2)
		T.is(ch[2], o2, 'Object inserted into middle gap in child list')
		T.ok(ch[1] == o1 and ch[3] == o3, '   Objects on either side of gap are unchanged')
		local indicesCorrect = ch[1]._index == 1 and ch[2]._index == 2 and ch[3]._index == 3
		T.ok(indicesCorrect, '   Indices of all children are correct.')
	end,

	function(scene)
		local p = Dummy()
		local o1, o2, o3 = Dummy(), Dummy(), Dummy()
		p.children = { o1, nil, o3 }
		scene:add(p)
		scene:add(o2, p, 10)
		T.is(p.children.maxn, 10, 'Inserting a child past maxn updates maxn correctly.')

		scene:swap(p, 10, 2)
		T.is(p.children.maxn, 3, 'Swapping that last child with nil shrinks maxn again correctly.')
	end,

	function(scene)
		local p = Dummy()
		local child = {}
		p.children = child
		for i=1,10 do  child[i] = Dummy()  end

		child[4] = nil -- Add a gap at index 4.
		scene:add(p)

		local maxn = child.maxn

		-- Insert child at index 2 (should push 2 & 3 up to 3 & 4, filling the gap).
		local testO = Dummy()
		local o2, o3, o5 = child[2], child[3], child[5]
		scene:add(testO, p, 2)

		-- Have to check the child AFTER the gap too, to make sure the gap was filled.
		local isCorrect = child[2] == testO and child[3] == o2 and child[4] == o3 and child[5] == o5
		T.ok(isCorrect, 'Inserting before a gap shifts up children and fills the gap.')

		T.is(p.children.maxn, maxn, '   Maxn is unchanged.')

		-- Double-check all child indices.
		for i=1,child.maxn do
			local c = child[i]
			if c then  T.is(c._index, i, '   Index of child['..i..'] is correct.')  end
		end
	end,

	function(scene)
		scene:add(Dummy())
		scene:add(Dummy())
		local IS_TOPDOWN = true
		local list = scene:getObjList(IS_TOPDOWN)
		T.is(#list, 3, "getObjList returns a list that's the correct length")
		T.is(list[1], scene, "getObjList - first in topdown list is the parent.")

		local uplist = scene:getObjList(not IS_TOPDOWN)
		T.is(#uplist, 3, "getObjList bottom-up returns a list that's the correct length")
		T.ok(uplist[1] ~= scene, "getObjList bottom-up - first in list is NOT the parent.")
		T.is(uplist[3], scene, "getObjList bottom-up - last in list is the parent.")
	end,

	function(scene) -- Check scene.updateTransforms().
		local pathsOfUpdated = ""
		local function ut(self)
			pathsOfUpdated = pathsOfUpdated .. self.path .. ", "
		end
		local function Obj()
			local o = Dummy()
			o.name = "Object"
			o.updateTransform = ut
			return o
		end
		scene:add(Obj())
		local p = scene:add(Obj())
		scene:add(Obj(), p)
		scene:add(Obj())
		pathsOfUpdated = "" -- Objects' transforms are updated when they are added.
		scene:updateTransforms()
		-- Top-down order.
		T.is(pathsOfUpdated, "/Object, /Object2, /Object2/Object, /Object3, ", "scene:updateTransforms() updates the transforms of all descendants.")
		pathsOfUpdated = ""
		scene:updateTransforms(p)
		T.is(pathsOfUpdated, "/Object2, /Object2/Object, ", "scene:updateTransforms(obj) updates 'obj' and its children.")
	end,
}
