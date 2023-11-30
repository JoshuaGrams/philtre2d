local base = (...):gsub('[^%.]+%.[^%.]+$', '')
local T = require(base .. 'lib.simple-test')

local SceneTree = require(base .. 'objects.SceneTree')
matrix = require(base .. 'core.matrix')
local gui = require(base .. 'objects.gui.all')
local Text = gui.Text

local function getDrawnImage(scene, w, h)
	local canvas = love.graphics.newCanvas(w, h)
	love.graphics.setCanvas(canvas)
	scene:draw()
	love.graphics.setCanvas()
	return canvas:newImageData()
end

local function isPixelDrawnAtAll(x, y, imgData)
	local r, g, b, a = imgData:getPixel(x - 1, y - 1) -- NOTE: x and y are 1-based.
	return a > 0
end

local function isAnythingDrawnInLine(x1, x2, y, imgData)
	for x=x1,x2 do
		if isPixelDrawnAtAll(x, y, imgData) then  return true  end
	end
end

return {
	setup = function() return SceneTree() end,
	"GUI Text",
	function(scene)
		local isSuccess, errMsg = pcall(Text, nil, "not a font")
		T.ok(not isSuccess, "Trying to create a Text node without a font table causes an error.")
		local isSuccess, errMsg = pcall(Text, nil, love.graphics.newFont(14))
		T.ok(not isSuccess, "Trying to create a Text node with a font object causes an error (should be a table).")
	end,
	function(scene)
		local isSuccess, errMsg = pcall(Text, nil, {nil, 12})
		T.ok(isSuccess, "Can create a text node using the default font (size arg only)")
	end,
	function(scene)
		local t = Text(nil, {nil, 12})
		T.is(t.text, "", "Nil `text` argument gets converted to an empty string on set().")
	end,
	function(scene)
		local t = scene:add(Text("blargle blargle blargle", {nil, 12}, 10))
		local isSuccess, errMsg = pcall(t.setWrap, t, true)
		T.ok(isSuccess, "setWrap(true) called without errors.")
	end,
	function(scene)
		local t = scene:add(Text("blargle blargle blargle", {nil, 12}, 20))
		local h = t.h
		t:setWrap(true)
		T.ok(t.h >= h*3, "Enabling wrap causes node height to increase to fit.")
		t:setWrap(false)
		T.is(t.h, h, "Disabling wrap again returns node to original height.")

		-- Test wrapping in set().
		local isWrapping = true
		local t2 = scene:add(Text("blargle blargle blargle", {nil, 12}, 20, nil, nil, nil, nil, isWrapping))
		T.ok(t2.h >= h*3, "Creating wrapping node increases node height roughly appropriately.")
	end,
	function(scene)
		local t = scene:add(Text("hi", {nil, 12}, 100, "px", "NW", "C", "left"))
		local drawn = getDrawnImage(scene, 100, 20)
		T.ok(isAnythingDrawnInLine(1, 20, 8, drawn), "Left-aligned text is drawn on the LEFT.")
		T.ok(not isAnythingDrawnInLine(80, 100, 8, drawn), "Left-aligned text is NOT drawn on the right.")
		T.ok(not isAnythingDrawnInLine(40, 60, 8, drawn), "Left-aligned text is NOT drawn in the center.")
		t:setAlign("right")
		local drawn = getDrawnImage(scene, 100, 20)
		T.ok(not isAnythingDrawnInLine(1, 20, 8, drawn), "Right-aligned text is NOT drawn on the left.")
		T.ok(isAnythingDrawnInLine(80, 100, 8, drawn), "Right-aligned text is drawn on the RIGHT.")
		T.ok(not isAnythingDrawnInLine(40, 60, 8, drawn), "Right-aligned text is NOT drawn in the center.")
		t:setAlign("center")
		local drawn = getDrawnImage(scene, 100, 20)
		T.ok(not isAnythingDrawnInLine(1, 20, 8, drawn), "Center-aligned text is NOT drawn on the left.")
		T.ok(not isAnythingDrawnInLine(80, 100, 8, drawn), "Center-aligned text is NOT drawn on the right.")
		T.ok(isAnythingDrawnInLine(40, 60, 8, drawn), "Center-aligned text is drawn in the CENTER.")
	end,
	function(scene)
		local t = scene:add(Text("hi", {nil, 12}))
		local originalFont = t.font
		t:allocate(0, 0, 100, 100, 2)
		T.ok(t.font ~= originalFont, "Font changes when allocated with scale.")
		local size = new.paramsFor[t.font][1]
		T.is(size, 24, "Font size scales up directly with allocated scale.")
		t:allocate(0, 0, 100, 100, 0.5)
		local size = new.paramsFor[t.font][1]
		T.is(size, 6, "Font size scales down directly with allocated scale.")
	end,
	function(scene)
		local s = scene:add(Text("hi", {nil, 12}))
		local testDebugDraw = function()
			s:debugDraw("default")
			scene:draw()
		end
		T.ok(pcall(testDebugDraw), "Debug draw runs without errors (just running to fill coverage).")
	end,
}
