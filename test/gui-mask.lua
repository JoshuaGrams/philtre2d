local base = (...):gsub('[^%.]+%.[^%.]+$', '')
local T = require(base .. 'lib.simple-test')

local SceneTree = require(base .. 'objects.SceneTree')
matrix = require(base .. 'core.matrix')
local gui = require(base .. 'objects.gui.all')
local Node = gui.Node
local Mask = gui.Mask

local function mod(obj, props)
	for name,prop in pairs(props) do
		obj[name] = prop
	end
	return obj
end

local function getDrawnImage(scene, w, h, useStencil)
	local canvas = love.graphics.newCanvas(w, h)
	if useStencil then
		love.graphics.setCanvas({ {canvas}, stencil=true })
	else
		love.graphics.setCanvas(canvas)
	end
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
	"GUI Mask",
	function(scene)
		if not T.ok(pcall(Mask), "Can create a mask node using no arguments.") then
			return
		end
		T.ok(pcall(scene.add, scene, Mask()), "Can add a mask node created using no arguments to a scene.")
	end,
	-- Add branches of children to Mask node (before init) and make sure 'maskObj' gets set on each one.
	function(scene)
		local m = mod(Mask(), { children = {
			mod(Node(), { children = {
				Node(),
				mod(Node(), {children = {
					Node(),
					Node()
				}}),
				Node(),
				Node()
			}}),
			Node(),
			mod(Node(), { children = {
				Node(),
				Node()
			}})
		}})
		local function childrenHaveMask(obj, maskObj)
			local children = obj.children
			if children then
				for i=1,children.maxn or #children do
					local child = children[i]
					if child then
						if not child.maskObj == maskObj then
							return
						end
						if not childrenHaveMask(child, maskObj) then
							return
						end
					end
				end
			end
			return true
		end
		scene:add(m)
		T.ok(childrenHaveMask(m, m), "All descendants of mask have mask set after init.")
		local new = mod(Node(), { children = { Node() } })
		scene:add(new, m.children[2])
		m:setMaskOnChildren()
		T.ok(childrenHaveMask(m, m), "After adding branch at runtime and calling setMaskOnChildren(), all descendants of mask have mask set.")
	end,
	-- Test mask drawing.
	function(scene)
		local childCol = { 1, 0, 0, 1 }
		local noCol = { 0, 0, 0, 0 }
		local function nodeDraw(self)
			love.graphics.setColor(childCol)
			love.graphics.rectangle('fill', -self.w/2, -self.h/2, self.w, self.h)
		end
		local m = mod(Mask(nil, 10, 10, "NW", "C"):setPos(10, 10), {children = {
			mod(Node(20, 20), {draw = nodeDraw})
		}})
		scene:add(m)
		scene:updateTransforms()
		local drawn = getDrawnImage(scene, 40, 40, true)
		-- pixels 1-10 are empty, 11-20 are inside mask, and 21-40 are empty.
		verifyPixel(10, 10, drawn, noCol, "Oversized child is masked from pixel off of mask top left corner.")
		verifyPixel(11, 11, drawn, childCol, "Oversized child is drawn in mask top left corner.")
		verifyPixel(20, 20, drawn, childCol, "Oversized child is drawn in mask bottom right corner.")
		verifyPixel(21, 21, drawn, noCol, "Oversized child is masked from pixel off of mask bottom right corner.")
		verifyPixel(15, 8, drawn, noCol, "Oversized child is masked from top.")
		verifyPixel(15, 22, drawn, noCol, "Oversized child is masked from bottom.")
		verifyPixel(9, 15, drawn, noCol, "Oversized child is masked from left.")
		verifyPixel(21, 15, drawn, noCol, "Oversized child is masked from right.")
	end,
	-- TODO: Test multiple overlapping masks.
	function(scene)
	end,
}
