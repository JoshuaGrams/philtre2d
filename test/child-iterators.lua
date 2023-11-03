local base = (...):gsub('[^%.]+.[^%.]+$', '')
local T = require 'lib.simple-test'

local SceneTree = require(base .. 'objects.SceneTree')
local Object = require(base .. 'objects.Object')
require(base .. 'core.child-iterators')

local function NamedObject(name)
	local o = Object()
	o.name = name
	return o
end

local function concatEverychild(children)
	local s = ''
	for i,child in everychild(children) do
		s = s .. ' ' .. i .. child.name
	end
	return s
end

local function concatForchildin(children)
	local s = ''
	forchildin(children, function(i, child)
		s = s .. ' ' .. i .. child.name
	end)
	return s
end

return {
	'Child Iterators - everychild',
	setup = function() return SceneTree() end,
	function(scene)
		scene:add(NamedObject('a'))
		scene:add(NamedObject('b'))
		scene:add(NamedObject('c'))
		local s = concatEverychild(scene.children)
		T.is(s, ' 1a 2b 3c', 'everychild iterator works on scene tree.')

		scene:remove(scene.children[2])
		local s = concatEverychild(scene.children)
		T.is(s, ' 1a 3c', 'everychild works with a list with a hole in it')

		scene:remove(scene.children[1])
		scene:remove(scene.children[3])
		local s = concatEverychild(scene.children)
		T.is(s, '', 'everychild works with all children removed')
	end,

	function(scene)
		scene:add(NamedObject('d'), nil, 4)
		local s = concatEverychild(scene.children)
		T.is(s, ' 4d', 'everychild works with child inserted off end of list')

		scene:swap(scene, 4, 8)
		local s = concatEverychild(scene.children)
		T.is(s, ' 8d', 'everychild works with child swapped further off end of list')

		scene:add(NamedObject('e'), nil, 3)
		scene:add(NamedObject('f'), nil, 7)
		scene:remove(scene.children[8])
		local s = concatEverychild(scene.children)
		T.is(s, ' 3e 7f', 'everychild works with new children inserted into middle and last one removed')
	end,

	'Child Iterators - forchildin',
	function(scene)
		scene:add(NamedObject('a'))
		scene:add(NamedObject('b'))
		scene:add(NamedObject('c'))
		local s = concatForchildin(scene.children)
		T.is(s, ' 1a 2b 3c', 'forchildin works on scene tree.')

		scene:remove(scene.children[2])
		local s = concatForchildin(scene.children)
		T.is(s, ' 1a 3c', 'forchildin works with a list with a hole in it')

		scene:remove(scene.children[1])
		scene:remove(scene.children[3])
		local s = concatForchildin(scene.children)
		T.is(s, '', 'forchildin works with all children removed')
	end,

	function(scene)
		scene:add(NamedObject('d'), nil, 4)
		local s = concatForchildin(scene.children)
		T.is(s, ' 4d', 'forchildin works with child inserted off end of list')

		scene:swap(scene, 4, 8)
		local s = concatForchildin(scene.children)
		T.is(s, ' 8d', 'forchildin works with child swapped further off end of list')

		scene:add(NamedObject('e'), nil, 3)
		scene:add(NamedObject('f'), nil, 7)
		scene:remove(scene.children[8])
		local s = concatForchildin(scene.children)
		T.is(s, ' 3e 7f', 'forchildin works with new children inserted into middle and last one removed')
	end,
}
