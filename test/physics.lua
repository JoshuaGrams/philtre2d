local base = (...):gsub('[^%.]+.[^%.]+$', '')
local T = require 'lib.simple-test'

local physics = require(base .. 'core.physics')

return {
   "Physics",
   function() -- Test `physics` module category helper stuff.
      physics.setCategoryNames("1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16")
      local cat = physics.getCategoriesBitmask("1", "3")
      T.is(cat, 5, "physics.getCategoriesBitmask works.")

      local success, err = pcall(physics.getCategoriesBitmask, "4", "12", "bob")
      T.is(success, false, "physics.getCategoriesBitmask errors when given a bogus category name.")

      local cat = physics.getMaskBitmask("6")
      T.is(cat, 65503, "physics.getMaskBitmask with one category works.")

      local cat = physics.getMaskBitmask("1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16")
      T.is(cat, 0, "physics.getMaskBitmask with all categories works.")

      local hasCat = physics.isInCategory(32 + 64 + 1, "6")
      T.is(hasCat, true, "physics.isInCategory works.")

      local hasCat = physics.isInCategory(64 + 1, "6")
      T.is(hasCat, false, "physics.isInCategory returns false correctly.")

      physics.setCategoryNames("cats", "mice")
      local catCats = physics.getCategoriesBitmask("cats") -- cats are cats
      local catMask = physics.getMaskBitmask("cats") -- cats avoid other cats, but are fine with mice.
      local mouseCats = physics.getCategoriesBitmask("mice") -- mice are mice
      local mouseMask = physics.getMaskBitmask("cats") -- mice avoid cats
      local canCollide = physics.shouldCollide(catCats, catMask, mouseCats, mouseMask)
      T.is(canCollide, false, "physics.shouldCollide - Mice avoid contact with cats even though the cats would be fine with it.")

      local mouseMask = physics.getMaskBitmask() -- These mice are fine with anybody.
      local canCollide = physics.shouldCollide(catCats, catMask, mouseCats, mouseMask)
      T.is(canCollide, true, "physics.shouldCollide - Mice that don't mind cats will be killed successfully.")
   end
}
