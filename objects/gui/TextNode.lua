local base = (...):gsub('[^%.]+$', '')
local Node = require(base .. 'Node')

local TextNode = Node:extend()
TextNode.className = 'TextNode'

local validHAlign = { center = true, left = true, right = true, justify = true }

function TextNode.updateScale(self, x, y, w, h, designW, designH, scale)
	local isDirty = TextNode.super.updateScale(self, x, y, w, h, designW, designH, scale)
	if isDirty then
		self.font = new.font(self.fontFilename, self.fontSize * scale)
		return true
	end
end

function TextNode.updateInnerSize(self, x, y, w, h, designW, designH, scale)
	local fontHeight = self.font:getHeight()
	local lineCount = 1
	if self.isWrapping or self.hAlign == "justify" then
		local textW, lines = self.font:getWrap(self.text, self.w)
		lineCount = math.max(1, #lines) -- Don't let line-count be zero. (as it would be with an empty string.)
	end
	self.h = fontHeight * lineCount
	self.designRect.h = self.h
	TextNode.super.updateInnerSize(self, x, y, w, h, designW, designH, scale)
end

local function debugDraw(self)
	love.graphics.setColor(self.debugColor)
	local pivotPosx, pivotPosy = self.w*self.px/2, self.h*self.py/2
	love.graphics.rectangle('line', -5+pivotPosx, -5+pivotPosy, 10, 10)
	love.graphics.circle('fill', pivotPosx, pivotPosy, 5, 4)
	love.graphics.rectangle('fill', -self.w*0.5, -self.h*0.5, self.w, self.h)
end

function TextNode.debugDraw(self, layer)
	if self.tree and self.drawIndex then
		self.tree.drawOrder:addFunction(layer, self._toWorld, debugDraw, self)
	end
end

function TextNode.draw(self)
	love.graphics.setBlendMode(self.blendMode)
	love.graphics.setFont(self.font)
	love.graphics.setColor(self.color)
	local w = self.w
	local ox, oy = w/2, self.h/2
	if not self.isWrapping and self.hAlign ~= "justify" then
		w = 1000000
		ox = w/2
		if self.hAlign == "left" then
			ox = ox - (w - self.w)/2
		elseif self.hAlign == "right" then
			ox = ox + (w - self.w)/2
		end
	end
	love.graphics.printf(
		self.text, 0, 0, w, self.hAlign,
		0, 1, 1, ox, oy, self.kx, self.ky
	)
end

function TextNode.setAlign(self, hAlign)
	assert(validHAlign[hAlign], 'TextNode.align: Invalid align "' .. tostring(hAlign) .. '". Must be "center", "left", "right", or "justify".')
	self.hAlign = hAlign
	return self
end

function TextNode.setWrap(self, isWrapping)
	local isDirty = isWrapping ~= self.isWrapping
	self.isWrapping = isWrapping
	if isDirty then  self:updateInnerSize()  end
	return self
end

function TextNode.set(self, text, font, w, pivot, anchor, hAlign, modeX, isWrapping)
	w = w or 100
	self.isWrapping = isWrapping
	local modeY = 'none' -- Height will adjust to fit wrapped text.
	self.text = text
	if type(font) == 'table' then -- {filename, size}
		self.font = new.font(unpack(font))
		self.fontFilename, self.fontSize = font[1], font[2]
	else
		error('TextNode: Invalid "font". Must give a table: {filename, size}.')
	end

	local fontHeight = self.font:getHeight()
	local lineCount = 1
	if self.isWrapping or hAlign == "justify" then
		local textW, lines = self.font:getWrap(self.text, w)
		lineCount = math.max(1, #lines) -- Don't let line-count be zero. (as it would be with an empty string.)
	end
	local h = fontHeight * lineCount

	TextNode.super.set(self, w, h, pivot, anchor, modeX, modeY)
	self.hAlign = validHAlign[hAlign] and hAlign or 'left'
	self.blendMode = 'alpha'
	self.color = {1, 1, 1, 1}
end

return TextNode
