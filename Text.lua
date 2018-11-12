local base = (...):gsub('[^%.]+$', '')
local Object = require(base .. 'Object')
local Text = Object:extend()
Text.className = 'Text'

function Text.draw(s)
	love.graphics.setFont(s.font)
	love.graphics.setColor(s.color)
	if s.wrapLimit then
		love.graphics.printf(s.text, 0, 0, s.wrapLimit, s.align, s.angle, 1, 1, 0, 0, s.kx, s.ky)
	else
		love.graphics.print(s.text, 0, 0, s.angle, 1, 1, 0, 0, s.kx, s.ky)
	end
end

local validAlignment = { center = true, left = true, right = true, justify = true }

function Text.set(self, text, font, x, y, angle, wrapLimit, align, sx, sy, kx, ky)
	Text.super.set(self, x, y, angle, sx, sy, kx, ky)
	self.color = {1, 1, 1, 1}
	self.text = text
	self.wrapLimit = wrapLimit
	self.align = validAlignment[align] and align or 'left'
	if type(font) == 'table' then -- {filename, size}
		self.font = new.font(unpack(font))
	else
		self.font = font
	end
end

return Text
