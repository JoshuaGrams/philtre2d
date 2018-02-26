local function wrapAngle(a)  -- to [-pi, pi).
	return (a + math.pi) % (2*math.pi) - math.pi
end

local function update(self, dt)
	self.pos.x = self.pos.x + dt * self.v.x
	self.pos.y = self.pos.y + dt * self.v.y
	self.angle = wrapAngle(self.angle + dt * self.vAngle)
end

local function draw(self)
	love.graphics.setColor(unpack(self.color))
	love.graphics.rectangle('fill', -self.w/2, -self.h/2, self.w, self.h)
end

local methods = { update = update, draw = draw }
local class = { __index = methods }

local function new(x, y, w, h, color)
	return setmetatable({
		pos = { x = x or 0, y = y or 0},
		v = { x = 0, y = 0 },
		angle = 0, vAngle = 0,
		w = w or 10, h = h or 10,
		color = color or { 128, 128, 128 }
	}, class)
end

return { new = new, methods = methods, class = class }
