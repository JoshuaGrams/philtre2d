local base = (...):gsub('[^%.]+$', '')
local Node = require(base .. 'Node')

local TextNode = Node:extend()
TextNode.className = 'TextNode'

local validHAlign = { center = true, left = true, right = true, justify = true }

function TextNode.updateScale(self, x, y, w, h, scale)
	local isDirty = TextNode.super.updateScale(self, x, y, w, h, scale)
	if isDirty then
		local size, file = self.fontSize * scale, self.fontFilename
		self.font = file and new.font(file, size) or new.font(size)
		return true
	end
end

function TextNode.updateContentSize(self, x, y, w, h, scale)
	local fontHeight = self.font:getHeight()
	local lineCount = 1
	if self.isWrapping or self.hAlign == "justify" then
		local textW, lines = self.font:getWrap(self.text, self.w)
		lineCount = math.max(1, #lines) -- Don't let line-count be zero. (as it would be with an empty string.)
	end
	self.h = fontHeight * lineCount
	return TextNode.super.updateContentSize(self, x, y, w, h, scale)
end

function TextNode.drawDebug(self) -- Normal Node.drawDebug, plus transparently filled rect.
	TextNode.super.drawDebug(self)
	local c = self.debugColor
	love.graphics.setColor(c[1], c[2], c[3], c[4]*0.2)
	love.graphics.rectangle('fill', 0.5, 0.5, self.w-1, self.h-1)
end

function TextNode.draw(self)
	love.graphics.setBlendMode(self.blendMode)
	love.graphics.setFont(self.font)
	love.graphics.setColor(self.color)
	local wrapW, ox = self.w, 0
	-- Justified text without wrapping doesn't make sense, so it always wraps with justify mode.
	if not self.isWrapping and self.hAlign ~= "justify" then
		-- With wrapping disabled, set huge wrap limit and manually re-align.
		-- Otherwise we would need to get the text width to align it.
		wrapW = 1000000
		if self.hAlign == "left" then
			ox = 0
		elseif self.hAlign == "right" then
			ox = self.w - wrapW
		else -- "center"
			ox = self.w/2 - wrapW/2
		end
	end
	-- If wrapping is enabled, then printf handles alignment as intended within our width.
	love.graphics.printf(
		self.text, ox, 0, wrapW, self.hAlign,
		0, 1, 1, 0, 0, self.kx, self.ky
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
	if isDirty then  self:updateContentSize(self.lastAlloc:unpack())  end
	return self
end

function TextNode.set(self, text, font, w, modeX, pivot, anchor, hAlign, isWrapping)
	w = w or 100
	self.isWrapping = isWrapping
	local modeY = 'pixels' -- Height will adjust to fit wrapped text.
	self.text = text or ''
	if type(font) == 'table' then -- {filename, size}
		local filename, size = font[1], font[2]
		self.font = filename and new.font(filename, size) or new.font(size)
		self.fontFilename, self.fontSize = filename, size
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

	TextNode.super.set(self, w, modeX, h, modeY, pivot, anchor)
	self.hAlign = validHAlign[hAlign] and hAlign or 'left'
	self.blendMode = 'alpha'
	self.color = {1, 1, 1, 1}
end

return TextNode
