local base = (...):gsub('[^%.]+$', '')
local Node = require(base .. 'Node')

local TextNode = Node:extend()
TextNode.className = 'TextNode'

local scaleFuncs = Node._scaleFuncs

local validHAlign = { center = true, left = true, right = true, justify = true }

function TextNode.updateScale(self, alloc)
	local isDirty = SliceNode.super.updateScale(self, alloc)
	if isDirty then
		local relScale = alloc.scale / self._myAlloc.scale
		self.fontSize = self.fontSize * relScale
		self.font = new.font(self.fontFilename, self.fontSize)
		return true
	end
end

function TextNode.updateInnerSize(self)
	local fontHeight = self.font:getHeight()
	local textW, lines = self.font:getWrap(self.text, self.w)
	local lineCount = #lines
	lineCount = lineCount == 0 and 1 or lineCount -- Don't let line-count be zero. (as it would be with an empty string.)
	self.h = fontHeight * lineCount
	TextNode.super.updateInnerSize(self)
end

local function debugDraw(self)
	love.graphics.setColor(self.debugColor)
	local pivotPosx, pivotPosy = self.w*self.px/2, self.h*self.py/2
	love.graphics.rectangle('line', -5+pivotPosx, -5+pivotPosy, 10, 10)
	love.graphics.circle('fill', pivotPosx, pivotPosy, 5, 4)
	love.graphics.rectangle('line', -self.w*0.5, -self.h*0.5, self.w, self.h)
end

function TextNode.debugDraw(self, layer)
	if self.tree then
		self.tree.draw_order:addFunction(layer, self._to_world, debugDraw, self)
	end
end

function TextNode.draw(self)
	love.graphics.setBlendMode(self.blendMode)
	love.graphics.setFont(self.font)
	love.graphics.setColor(self.color)
	local ox, oy = self.w/2, self.h/2
	love.graphics.printf(
		self.text, 0, 0, self.w, self.hAlign,
		0, 1, 1, ox, oy, self.kx, self.ky
	)
end

function TextNode.set(self, text, font, x, y, angle, w, px, py, ax, ay, hAlign, modeX)
	local modeY = 'none' -- Height will adjust to fit wrapped text.
	self.text = text
	if type(font) == 'table' then -- {filename, size}
		self.font = new.font(unpack(font))
		self.fontFilename, self.fontSize = font[1], font[2]
	else
		error('TextNode: Invalid "font". Must give a table: {filename, size}.')
	end
	local fontHeight = self.font:getHeight()
	local w, lines = self.font:getWrap(self.text, self.w)
	self.h = fontHeight * #lines
	TextNode.super.set(self, x, y, angle, w, nil, px, py, ax, ay, modeX, modeY)
	self.hAlign = validHAlign[hAlign] and hAlign or 'left'
	self.blendMode = 'alpha'
	self.color = {1, 1, 1, 1}
end

return TextNode
