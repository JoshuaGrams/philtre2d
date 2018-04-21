
local matrix = require 'engine.matrix'
local Object = require 'engine.Object'

local Body = Object:extend()

Body.className = 'Body'

function Body.draw(self)
	-- physics debug
	love.graphics.setColor(self.color)
	local cx, cy = self.body:getLocalCenter()
	love.graphics.circle('fill', cx, cy, 3, 4) -- dot at center of mass
	love.graphics.line(cx, cy, cx + 10, cy + 0) -- x axis line
	for i,f in ipairs(self.body:getFixtureList()) do
		local s = f:getShape()
		if s:getType() == 'circle' then
			local x, y = s:getPoint()
			love.graphics.circle('line', x, y, s:getRadius(), 24)
		else
			love.graphics.polygon('line', {s:getPoints()})
		end
	end
end

function Body.update(self, dt)
	if self.type == 'kinematic' then
		-- Pos in local space, must update physics world pos to match.
		self.body:setPosition(matrix.x(self.parent._to_world, self.pos.x, self.pos.y))
		local th, sx, sy = matrix.parameters(self.parent._to_world)
		self.body:setAngle(th)
		 -- body can't scale, set to inverted _to_world scale to enforce this.
		self.sx, self.sy = 1/sx, 1/sy
	else -- 'dynamic' or 'static'
		-- Pos controlled by physics in world space, update obj pos to match.
		self.pos.x, self.pos.y = self.body:getPosition()
		self.angle = self.body:getAngle()
	end
end

local body_set_funcs = {
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

function Body.init(self)
	if not self.ignore_transform and self.type ~= 'kinematic' then
		self.pos.x, self.pos.y = matrix.x(self.parent._to_world, self.pos.x, self.pos.y)
		self.angle = self.angle + matrix.parameters(self.parent._to_world)
	end

	self.body = love.physics.newBody(self.world, self.pos.x, self.pos.y, self.type)
	self.body:setAngle(self.angle)
	if self.bodyData then
		for k,v in pairs(self.bodyData) do
			if body_set_funcs[k] then self.body[body_set_funcs[k]](self.body, v) end
		end
	end

	for i,s in ipairs(self.shapeData) do
		-- s[1] = shape type, s[2] = shape specs
		local shape = shape_constructors[s[1]](unpack(s[2]))
		local f = love.physics.newFixture(self.body, shape, s.density)
		f:setUserData(self.path)
		for k,v in pairs(s) do
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
	self.inherit = nil
end

function Body.final(self)
	self.body:destroy()
end

function Body.set(self, world, type, x, y, angle, shapes, body_prop, ignore_parent_transform)
	Body.super.set(self, x, y, angle)
	local rand = love.math.random
	self.color = {rand()*200+55, rand()*200+55, rand()*200+55, 255}
	self.type = type
	if self.type ~= 'kinematic' then
		self.updateTransform = Object.TRANSFORM_ABSOLUTE
	end
	-- Save to use on init:
	self.world = world
	self.shapeData = shapes
	self.bodyData = body_prop
	self.ignore_transform = ignore_parent_transform
end

return Body
