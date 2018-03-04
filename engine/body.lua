local T = require('engine.scene-tree')
local M = require('engine.matrix')

local function draw(self)
	for i, f in ipairs(self.body:getFixtureList()) do
		local s = f:getShape()
		if s:getType() == 'circle' then
			local x, y = s:getPoint()
			love.graphics.circle('line', x, y, s:getRadius(), 32)
		else
			love.graphics.polygon('line', {s:getPoints()})
		end
	end
end

local function update(self, dt)
	if self.type == 'kinematic' then
		self.body:setPosition(T.to_world(self.parent, self.pos.x, self.pos.y))
		local th, sx, sy = M.parameters(self._to_world)
		self.body:setAngle(th)
		self.sx, self.sy = 1/sx, 1/sy
	else
		self.pos.x, self.pos.y = self.body:getPosition()
		self.angle = self.body:getAngle()
	end
end

local body_set_funcs = {
	angle = 'setAngle',
	linDamp = 'setLinearDamping',
	angDamp = 'setAngularDamping',
	bullet = 'setBullet',
	fixedRot = 'setFixedRotation',
	gScale = 'setGravityScale'
}

local fixture_set_funcs = {
	sensor = 'setSensor',
	groups = 'setCategory',
	masks = 'setMask',
	friction = 'setFriction',
	restitution = 'setRestitution'
}

local shape_constructors = {
	circle = love.physics.newCircleShape, -- radius OR x, y radius
	rectangle = love.physics.newRectangleShape, -- width, height OR x, y, width, height, angle
	polygon = love.physics.newPolygonShape, -- x1, y1, x2, y2, x3, y3, ... - up to 8 verts
	edge = love.physics.newEdgeShape, -- x1, y1, x2, y2
	chain = love.physics.newChainShape, -- loop, points OR loop, x1, y1, x2, y2 ... no vert limit
}

local function init(self)
	if self.type ~= 'kinematic' then
		self.absolute_coords = true
		self.pos.x, self.pos.y = T.to_world(self.parent, self.pos.x, self.pos.y)
	end
	self.body = love.physics.newBody(self.world, self.pos.x, self.pos.y, self.type)
	if self.bodyData then
		for k, v in pairs(self.bodyData) do
			if body_set_funcs[k] then self.body[body_set_funcs[k]](self.body, v) end
		end
	end

	for i, s in ipairs(self.shapeData) do
		-- s[1] = shape type, s[2] = shape specs
		local shape = shape_constructors[s[1]](unpack(s[2]))
		local f = love.physics.newFixture(self.body, shape, s.density)
		for k, v in pairs(s) do
			if fixture_set_funcs[k] then
				if k == 'groups' or k == 'masks' then
					f[fixture_set_funcs[k]](f, unpack(v))
				else
					f[fixture_set_funcs[k]](f, v)
				end
			end
		end
	end

	self.world = nil
	self.shapeData = nil
	self.bodyData = nil
end

local methods = { update = update, draw = draw, init = init }
local class = { __index = methods }

local function new(world, type, x, y, shapes, prop)
	local body = T.object(x, y)
	body.type = type
	-- save to use on init:
	body.world = world
	body.shapeData = shapes
	body.bodyData = prop
	return setmetatable(body, class)
end

return { new = new, methods = methods, class = class }
