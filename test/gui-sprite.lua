local base = (...):gsub('[^%.]+%.[^%.]+$', '')
local T = require(base .. 'lib.simple-test')

local SceneTree = require(base .. 'objects.SceneTree')
matrix = require(base .. 'core.matrix')
local gui = require(base .. 'objects.gui.all')
local Node = gui.Node
local Sprite = gui.Sprite

local img
local imgCol = { 0.5, 0.6, 0.7, 1 }
do
	local canvas = love.graphics.newCanvas(100, 100)
	love.graphics.setCanvas(canvas)
	love.graphics.setColor(imgCol)
	love.graphics.rectangle("fill", 0, 0, 100, 100)
	love.graphics.setCanvas()
	local imgData = canvas:newImageData()
	img = love.graphics.newImage(imgData, {linear = true})
end

local function checkPixel(x, y, imgData, col, msg, tol)
	tol = tol or 0.005
	local r, g, b, a = imgData:getPixel(x, y)
	T.ok(math.abs(r - col[1]) <= tol, "(r) "..msg)
	T.ok(math.abs(g - col[2]) <= tol, "(g) "..msg)
	T.ok(math.abs(b - col[3]) <= tol, "(b) "..msg)
	T.ok(math.abs(a - col[4]) <= tol, "(a) "..msg)
end

return {
	"GUI Sprite",
	function()
		local isSuccess, sprite = pcall(Sprite, img)
		T.ok(isSuccess and sprite:is(Sprite), "SpriteNode constructor works, returns a SpriteNode.")
	end,
	function() -- Test constructor with invalid images.
		local invalidImageArg = 1
		local isSuccess, result = pcall(Sprite, invalidImageArg)
		T.ok(not isSuccess, "Invalid `image` to constructor results in a custom error: \n\t" .. tostring(result))
		-- Also test with another userdata type.
		local invalidImageArg = love.graphics.newCanvas(16, 16)
		local isSuccess, result = pcall(Sprite, invalidImageArg)
		T.ok(not isSuccess, "Invalid userdata `image` to constructor results in a custom error: \n\t" .. tostring(result))
	end,
	function(scene)
		local scene = SceneTree()
		-- NW corner at 0, 0.
		local sprite = scene:add(Sprite(img, nil, nil, nil, "NW", "C", "stretch", "stretch"))
		local canvas = love.graphics.newCanvas(200, 200)
		love.graphics.setCanvas(canvas)
		scene:draw()
		love.graphics.setCanvas()
		local drawn = canvas:newImageData()
		local noCol = { 0, 0, 0, 0 }
		checkPixel(0, 0, drawn, imgCol, "Top left pixel of node on 'screen' is correct.")
		checkPixel(99, 99, drawn, imgCol, "Bottom right pixel of node on 'screen' is correct.")
		checkPixel(100, 100, drawn, noCol, "Pixel off bottom right corner is correct.")
		checkPixel(100, 50, drawn, noCol, "Pixel off right side is correct.")
		checkPixel(50, 100, drawn, noCol, "Pixel off bottom sides is correct.")

		sprite:allocate(0, 0, 50, 75, 100, 100, 1)
		T.has(sprite, {sx=0.5,sy=0.75}, "Allocated SpriteNode has correct image scale.")

		love.graphics.setCanvas(canvas)
		love.graphics.clear()
		scene:draw()
		love.graphics.setCanvas()
		local drawn = canvas:newImageData()
		-- SpriteNode size is now 50, 75.
		checkPixel(0, 0, drawn, imgCol, "Top left pixel of node on 'screen' is correct.")
		checkPixel(49, 74, drawn, imgCol, "Bottom right pixel of node on 'screen' is correct.")
		checkPixel(50, 75, drawn, noCol, "Pixel off bottom right corner is correct.")
		checkPixel(50, 37, drawn, noCol, "Pixel off right side is correct.")
		checkPixel(37, 75, drawn, noCol, "Pixel off bottom sides is correct.")
	end,
}
