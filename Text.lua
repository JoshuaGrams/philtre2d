local base = (...):gsub('[^%.]+$', '')
local Object = require(base .. 'Object')
local Text = Object:extend()
Text.className = 'Text'

function Text.draw(s)
	love.graphics.setFont(s.font)
	love.graphics.setColor(s.color)
	love.graphics.printf(s.text, -s.ox, -s.oy, s.wrap_limit, s.align, s.angle, 1, 1, 0, 0, s.kx, s.ky)
end

local aligns = { center = true, left = true, right = true, justify = true }

function Text.set(self, x, y, angle, text, font_filename, font_size, wrap_limit, align, sx, sy, kx, ky)
	Text.super.set(self, x, y, angle, sx, sy, kx, ky)
	self.color = {255, 255, 255, 255}
	self.text = text
	self.wrap_limit = wrap_limit or 300
	self.ox = self.wrap_limit/2;  self.oy = 0
	self.align = aligns[align] and align or 'center'
	self.font_size = font_size or 24
	if type(font_filename) == 'string' then
		self.font = love.graphics.newFont(font_filename, self.font_size)
	else
		self.font = love.graphics.newFont(self.font_size)
	end
end

return Text
