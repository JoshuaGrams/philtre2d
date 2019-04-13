local base = (...):gsub('[^%.]+$', '')
local Object = require(base .. 'Object')
local Text = Object:extend()
Text.className = 'Text'

local validAlignment = { center = true, left = true, right = true, justify = true }
local hOffset = { center = -0.5, left = 0, right = -1, justify = 0 }
local vOffset = { top = 0, middle = -0.5, bottom = -1 }

function Text.draw(s)
	love.graphics.setBlendMode(s.blendMode)
	love.graphics.setFont(s.font)
	love.graphics.setColor(s.color)
	if s.wrapLimit then
		local ox = hOffset[s.hAlign] * s.wrapLimit
		local oy = vOffset[s.vAlign] * s.font:getHeight()
		love.graphics.printf(s.text, 0, 0, s.wrapLimit, s.hAlign, s.angle, 1, 1, 0, 0, s.kx, s.ky)
	else
		love.graphics.print(s.text, 0, 0, s.angle, 1, 1, 0, 0, s.kx, s.ky)
	end
end

function Text.set(self, text, font, x, y, angle, wrapLimit, hAlign, sx, sy, kx, ky)
	Text.super.set(self, x, y, angle, sx, sy, kx, ky)
	self.blendMode = 'alpha'
	self.color = {1, 1, 1, 1}
	self.text = text
	self.wrapLimit = wrapLimit
	self.hAlign = validAlignment[hAlign] and hAlign or 'left'
	self.vAlign = (self.hAlign == 'center') and 'middle' or 'top'
	if type(font) == 'table' then -- {filename, size}
		self.font = new.font(unpack(font))
	else
		self.font = font
	end
end

return Text
