local base = (...):gsub('[^%.]+%.[^%.]+$', '')
local T = require(base .. 'lib.simple-test')

local SceneTree = require(base .. 'objects.SceneTree')
matrix = require(base .. 'core.matrix')
new = require(base .. 'core.new')
local gui = require(base .. 'objects.gui.all')
local Node = gui.Node
local Slice = gui.Slice

local tlCol = {0, 0, 0, 1}
local trCol = {1, 0, 0, 1}
local blCol = {0, 1, 0, 1}
local brCol = {1, 1, 0, 1}
local ltCol = {0, 0.5, 0, 1}
local rtCol = {1, 0.5, 0, 1}
local topCol = {0.5, 0, 0, 1}
local botCol = {0.5, 1, 0, 1}
local ctrCol = {0.5, 0.5, 0, 1}

local function rect(x, y, rt, bot, col)
	love.graphics.setColor(col)
	local w, h = rt - x, bot - y
	love.graphics.rectangle("fill", x, y, w, h)
end

local function makeSliceImg(w, h, lt, rt, top, bot)
	local canvas = love.graphics.newCanvas(w, h)
	love.graphics.setCanvas(canvas)
	rt, bot = w - rt, h - bot -- Make absolute instead of relative to edges.
	rect(0, 0, lt, top, tlCol) -- top-left corner
	rect(rt, 0, w, top, trCol) -- top-right corner
	rect(0, bot, lt, h, blCol) -- bot-left corner
	rect(rt, bot, w, h, brCol) -- bot-right corner
	rect(0, top, lt, bot, ltCol) -- left side
	rect(rt, top, w, bot, rtCol) -- right side
	rect(lt, 0, rt, top, topCol) -- top side
	rect(lt, bot, rt, h, botCol) -- bottom side
	rect(lt, top, rt, bot, ctrCol) -- center
	love.graphics.setCanvas()
	return love.graphics.newImage( canvas:newImageData() )
end

local function getDrawnImage(scene, w, h)
	local canvas = love.graphics.newCanvas(w, h)
	love.graphics.setCanvas(canvas)
	scene:draw()
	love.graphics.setCanvas()
	return canvas:newImageData()
end

local function verifyPixel(x, y, imgData, col, msg, tol)
	tol = tol or 0.005
	local r, g, b, a = imgData:getPixel(x - 1, y - 1) -- NOTE: x and y are 1-based.
	local isGood = math.abs(r - col[1]) <= tol and
	               math.abs(g - col[2]) <= tol and
	               math.abs(b - col[3]) <= tol and
	               math.abs(a - col[4]) <= tol
	T.ok(isGood, msg)
end

return {
	setup = function() return SceneTree() end,
	"GUI Slice",
	function(scene)
		local img = makeSliceImg(20, 20, 1, 2, 3, 4)
		local s = scene:add(Slice(img, nil, {1, 2, 3, 4}, 20, "px", 20, "px")) -- lt, rt, top, bot
		local drawn = getDrawnImage(scene, 25, 25)
		local lt, rt = 1, 20-2+1
		local top, bot = 3, 20-4+1
		-- top-left corner
		verifyPixel(1, 1, drawn, tlCol, "Top left of top left corner is correct.")
		verifyPixel(1, top, drawn, tlCol, "Bottom right of top left corner is correct.")
		-- top-right corner
		verifyPixel(rt, 1, drawn, trCol, "Top left of top right corner is correct.")
		verifyPixel(20, top, drawn, trCol, "Bottom right of top right corner is correct.")
		-- bot-left corner
		verifyPixel(1, bot, drawn, blCol, "Top left of bottom left corner is correct.")
		verifyPixel(1, 20, drawn, blCol, "Bottom right of bottom left corner is correct.")
		-- bot-right corner
		verifyPixel(rt, bot, drawn, brCol, "Top left of bottom right corner is correct.")
		verifyPixel(20, 20, drawn, brCol, "Bottom right of bottom right corner is correct.")
		-- left side
		verifyPixel(1, top+1, drawn, ltCol, "Top left of left side is correct.")
		verifyPixel(1, bot-1, drawn, ltCol, "Bottom right of left side is correct.")
		-- right side
		verifyPixel(rt, top+1, drawn, rtCol, "Top left of right side is correct.")
		verifyPixel(20, bot-1, drawn, rtCol, "Bottom right of right side is correct.")
		-- top side
		verifyPixel(lt+1, 1, drawn, topCol, "Top left of top side is correct.")
		verifyPixel(rt-1, top, drawn, topCol, "Bottom right of top side is correct.")
		-- bottom side
		verifyPixel(lt+1, bot, drawn, botCol, "Top left of bottom side is correct.")
		verifyPixel(rt-1, 20, drawn, botCol, "Bottom right of bottom side is correct.")
		-- center
		verifyPixel(lt+1, top+1, drawn, ctrCol, "Top left of center is correct.")
		verifyPixel(rt-1, bot-1, drawn, ctrCol, "Bottom right of center is correct.")
		verifyPixel(10, 10, drawn, ctrCol, "Center of center is correct.")
	end,
	function(scene)
		-- Check that margins scale.
		love.graphics.setDefaultFilter("nearest")
		local img = makeSliceImg(20, 20, 2, 2, 2, 2)
		local s = scene:add(Slice(img, nil, {2}, 100, "%", 100, "%")) -- lt, rt, top, bot
		s:allocate(0, 0, 20, 20, 2)
		local drawn = getDrawnImage(scene, 22, 22)
		local lt, rt = 4, 20-4+1
		local top, bot = 4, 20-4+1
		-- top-left corner
		verifyPixel(1, 1, drawn, tlCol, "Top left of top left corner is correct after scaling.")
		verifyPixel(1, top, drawn, tlCol, "Bottom right of top left corner is correct after scaling.")
		-- top-right corner
		verifyPixel(rt, 1, drawn, trCol, "Top left of top right corner is correct after scaling.")
		verifyPixel(20, top, drawn, trCol, "Bottom right of top right corner is correct after scaling.")
		-- bot-left corner
		verifyPixel(1, bot, drawn, blCol, "Top left of bottom left corner is correct after scaling.")
		verifyPixel(1, 20, drawn, blCol, "Bottom right of bottom left corner is correct after scaling.")
		-- bot-right corner
		verifyPixel(rt, bot, drawn, brCol, "Top left of bottom right corner is correct after scaling.")
		verifyPixel(20, 20, drawn, brCol, "Bottom right of bottom right corner is correct after scaling.")
		-- left side
		verifyPixel(1, top+1, drawn, ltCol, "Top left of left side is correct after scaling.")
		verifyPixel(1, bot-1, drawn, ltCol, "Bottom right of left side is correct after scaling.")
		-- right side
		verifyPixel(rt, top+1, drawn, rtCol, "Top left of right side is correct after scaling.")
		verifyPixel(20, bot-1, drawn, rtCol, "Bottom right of right side is correct after scaling.")
		-- top side
		verifyPixel(lt+1, 1, drawn, topCol, "Top left of top side is correct after scaling.")
		verifyPixel(rt-1, top, drawn, topCol, "Bottom right of top side is correct after scaling.")
		-- bottom side
		verifyPixel(lt+1, bot, drawn, botCol, "Top left of bottom side is correct after scaling.")
		verifyPixel(rt-1, 20, drawn, botCol, "Bottom right of bottom side is correct after scaling.")
		-- center
		verifyPixel(lt+1, top+1, drawn, ctrCol, "Top left of center is correct after scaling.")
		verifyPixel(rt-1, bot-1, drawn, ctrCol, "Bottom right of center is correct after scaling.")
		verifyPixel(10, 10, drawn, ctrCol, "Center of center is correct after scaling.")
	end,
	-- TODO: Test that slices work correctly after node resizing.
	function(scene)
		local img = makeSliceImg(20, 20, 2, 2, 2, 2)
		local s = scene:add(Slice(img, nil, {2}))
		local testDebugDraw = function()
			s:debugDraw("default")
			scene:draw()
		end
		T.ok(pcall(testDebugDraw), "Debug draw runs without errors (just running to fill coverage).")
	end,
}
