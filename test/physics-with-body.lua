local base = (...):gsub('[^%.]+.[^%.]+$', '')
local T = require 'lib.simple-test'

local physics = require(base .. 'core.physics')
local body = require(base .. 'objects.Body')
DrawOrder = require(base .. 'render.draw-order') -- SceneTree requires this as a global.
local SceneTree = require(base .. 'objects.SceneTree')
local World = require(base .. 'objects.World')
local Body = require(base .. 'objects.Body')

local scene, world

return {
	"Physics Integration with Body",
	setup = function()
		physics.setCategoryNames("cats", "mice", "dogs", "cows", "rabbits")
		scene = SceneTree({"default"})
		world = World()
		scene:add(world)
	end,
	teardown = function()
		scene:remove(world)
	end,
	function() -- Integration test with Body.
		local success, result = pcall(Body, "static", 0, 0, 0, {"circle", {50}})
		local b = result
		T.is(success, true, "We can create a Body. " .. tostring(result or ""))
		if not success then  T.bail("...that failed, aborting test.")  end
		local success, result = pcall(scene.add, scene, b, world)
		T.is(success, true, "We can add the Body to the scene-tree. " .. tostring(result or ""))
		if not success then  T.bail("...that failed, aborting test.")  end
	end,
	function()
		local cat = physics.getCategoriesBitmask("cats")
		print("    Giving a 'categories' bitmask to Body()...")
		local b = Body("static", 0, 0, 0, {"circle", {50}, categories = cat})
		scene:add(b, world)
		T.ok(true, "...works.")
	end,
	function()
		local cat = physics.getCategoriesBitmask("cats", "mice", "cows")
		print("    Giving a 'categories' bitmask with multiple categories to Body()...")
		local b = Body("static", 0, 0, 0, {"circle", {50}, categories = cat})
		scene:add(b, world)
		T.ok(true, "...works.")
	end,
	function()
		local mask = physics.getMaskBitmask("mice", "dogs")
		print("    Giving a 'mask' bitmask to Body()...")
		local b = Body("static", 0, 0, 0, {"circle", {50}, mask = mask})
		scene:add(b, world)
		T.ok(true, "...works.")
	end,
	function()
		local cat = physics.getCategoriesBitmask("cats", "mice", "cows")
		local mask = physics.getMaskBitmask("mice", "rabbits")
		print("    Giving both 'categories' and 'mask' bitmasks to Body()...")
		local b = Body("static", 0, 0, 0, {"circle", {50}, categories = cat, mask = mask, sensor = true})
		scene:add(b, world)
		T.ok(true, "...works.")

		local f = b.body:getFixtures()[1]
		local catA, maskA, groupA = f:getFilterData()
		T.is(physics.isInCategory(cat, "cows"), true, "Body fixture is indeed a cow. physics.isInCategory works.")
		T.is(physics.isInCategory(mask, "mice"), false, "Body fixture won't hit mice.")
		T.is(physics.isInCategory(mask, "dogs"), true, "Body fixture will hit dogs.")

		-- Check if physics.shouldCollide matches "real world" behavior.

		local cat2 = physics.getCategoriesBitmask("dogs")
		local mask2 = physics.getMaskBitmask("mice", "cats")

		T.ok(physics.shouldCollide(cat, mask, cat2, mask2), "Cat-mouse-cow should hit dog that doesn't like mice or cats.")

		local didHit = false
		function b.beginContact(self, self_fixture, other_fixture, other_object, contact)
			didHit = true
		end
		local b2 = Body("dynamic", 0, 0, 0, {"circle", {50}, categories = cat2, mask = mask2, sensor = true})
		scene:add(b2, world)
		world.world:update(1/60)
		T.ok(didHit, "  Yup, that works in the real world too.")

		local mask3 = physics.getMaskBitmask("mice", "cats", "cows")

		T.ok(not physics.shouldCollide(cat, mask, cat2, mask3), "Cat-mouse-cow should NOT hit dog that doesn't like mice, cats, OR cows.")

		local didntHit = true
		function b.beginContact(self, self_fixture, other_fixture, other_object, contact)
			didntHit = false
		end
		local b3 = Body("dynamic", 0, 0, 0, {"circle", {50}, categories = cat2, mask = mask3, sensor = true})
		scene:add(b3, world)
		world.world:update(1/60)
		T.ok(didntHit, "  That also matches real-world behavior.")
	end,
}
