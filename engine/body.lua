local T = require('engine.scene-tree')
local M = require('engine.matrix')

local function draw(self)
	-- for each fixture...
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
	if self.type == 'kinematic' then
		self.body:setPosition(T.to_world(self.parent, self.pos.x, self.pos.y))
		local th = M.parameters(self._to_world)
		self.body:setAngle(th)
	else
		self.pos.x, self.pos.y = self.body:getPosition()
		self.angle = self.body:getAngle() -- (self.parent and self.parent.angle or 0)
	end
end

local function init(self)
	if self.type ~= 'kinematic' then
		self.absolute_coords = true
		self.pos.x, self.pos.y = T.to_world(self.parent, self.pos.x, self.pos.y)
	end
	self.body = love.physics.newBody(self.world, self.pos.x, self.pos.y, self.type)
	self.f = love.physics.newFixture(self.body, self.s)
	self.world = nil
end

local methods = { update = update, draw = draw, init = init }
local class = { __index = methods }

local shapes = {
	circle = love.physics.newCircleShape, -- radius OR x, y radius
	rectangle = love.physics.newRectangleShape, -- width, height OR x, y, width, height, angle
	polygon = love.physics.newPolygonShape, -- x1, y1, x2, y2, x3, y3, ... - up to 8 verts
	edge = love.physics.newEdgeShape, -- x1, y1, x2, y2
	chain = love.physics.newChainShape, -- loop, points OR loop, x1, y1, x2, y2 ... no vert limit
}

local function new(world, type, x, y, shapeData, ...)
	local body = T.object(x, y, 0)
	body.world = world
	body.type = type
	body.shapeType = shapeData
	body.s = shapes[shapeData](...)
	local shape_args = {...}
	if shapeData == 'circle' then body.radius = shape_args[1]
	elseif shapeData == 'rectangle' then body.width = shape_args[1];  body.height = shape_args[2]
	else body.points = shape_args -- polygon, edge, chain
	end


	return setmetatable(body, class)
end

return { new = new, methods = methods, class = class }