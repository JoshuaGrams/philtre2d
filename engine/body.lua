local T = require('engine.scene-tree')

local function draw(self)
	if self.shapeType == 'circle' then
		love.graphics.circle('line', 0, 0, self.radius, 32)
	elseif self.shapeType == 'rectangle' then
		love.graphics.rectangle('line', -self.width/2, -self.height/2, self.width, self.height)
	elseif self.shapeType == 'polygon' then
		love.graphics.polygon('line', self.points)
	else -- edge and chain
		love.graphics.line(self.points)
	end
end

local function update(self, dt)
	self.pos.x, self.pos.y = self.body:getPosition()
	self.angle = self.body:getAngle()
end

local methods = { update = update, draw = draw }
local class = { __index = methods }

local shapes = {
	circle = love.physics.newCircleShape, -- radius OR x, y radius
	rectangle = love.physics.newRectangleShape, -- width, height OR x, y, width, height, angle
	polygon = love.physics.newPolygonShape, -- x1, y1, x2, y2, x3, y3, ... - up to 8 verts
	edge = love.physics.newEdgeShape, -- x1, y1, x2, y2
	chain = love.physics.newChainShape, -- loop, points OR loop, x1, y1, x2, y2 ... no vert limit
}

local function new(world, type, x, y, shape, ...) -- {...} is shape data
	local body = T.object(x, y, 0)
	body.body = love.physics.newBody(world, x, y, type)
	body.shapeType = shape
	body.s = shapes[shape](...)
	local shape_args = {...}
	if shape == 'circle' then body.radius = shape_args[1]
	elseif shape == 'rectangle' then body.width = shape_args[1];  body.height = shape_args[2]
	else body.points = shape_args -- polygon, edge, chain
	end
	body.f = love.physics.newFixture(body.body, body.s)
	return setmetatable(body, class)
end

return { new = new, methods = methods, class = class }