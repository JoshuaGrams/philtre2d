local base = (...):gsub('[^%.]+$', '')
local matrix = require(base .. 'matrix')
local Object = require(base .. 'Object')
local World = require(base .. 'World')

local Body = Object:extend()

Body.className = 'Body'

function Body.draw(self)
	-- physics debug
	love.graphics.setBlendMode('alpha')
	love.graphics.setColor(self.color)
	local cx, cy = self.body:getLocalCenter()
	love.graphics.circle('fill', cx, cy, 3, 4) -- dot at center of mass
	love.graphics.line(cx, cy, cx + 10, cy + 0) -- x axis line
	for i,f in ipairs(self.body:getFixtures()) do
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
	categories = 'setCategory',
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

local function getWorld(parent)
	if not parent then
		return
	elseif parent.is and parent:is(World) and parent.world then
		return parent.world
	else
		return getWorld(parent.parent)
	end
end

-- Sets the masks for all fixtures on the body.
function Body.setMasks(self, maskList)
	if not self.body then
		print('WARNING: Body.setMasks - Can\'t set masks before physics body has been created.')
		return
	end
	local fixtures = self.body:getFixtureList()
	for i,f in ipairs(fixtures) do
		f:setMask(unpack(maskList))
	end
end

local function makeFixture(self, data)
	-- data[1] = shape type, data[2] = shape specs, data[...] = fixture props.
	local shape = shape_constructors[data[1]](unpack(data[2]))
	local f = love.physics.newFixture(self.body, shape, data.density)
	f:setUserData(self) -- Store self ref on each fixture for collision callbacks.
	-- Discard already-used data, leaving only fixture properties (if any).
	data[1], data[2], data.density = nil, nil, nil
	for k,v in pairs(data) do
		if fixture_set_funcs[k] then
			if k == 'categories' or k == 'masks' then
				f[fixture_set_funcs[k]](f, unpack(v))
			else
				f[fixture_set_funcs[k]](f, v)
			end
		end
	end
end

function Body.init(self)
	if not self.ignore_transform and self.type ~= 'kinematic' then
		self.pos.x, self.pos.y = matrix.x(self.parent._to_world, self.pos.x, self.pos.y)
		self.angle = self.angle + matrix.parameters(self.parent._to_world)
	end

	local world = getWorld(self.parent)
	self.world = world
	if not world then
		error('Body.init ' .. tostring(self) .. ' - No parent World found. Bodies must be descendants of a World object.')
	end
	-- Make body.
	self.body = love.physics.newBody(world, self.pos.x, self.pos.y, self.type)
	self.body:setAngle(self.angle)
	if self.bodyData then
		for k,v in pairs(self.bodyData) do
			if body_set_funcs[k] then self.body[body_set_funcs[k]](self.body, v) end
		end
	end
	-- Make shapes & fixtures.
	if type(self.shapeData[1]) == 'string' then -- Only one fixture def.
		makeFixture(self, self.shapeData)
	else
		for i, data in ipairs(self.shapeData) do -- A list of fixture defs.
			makeFixture(self, data)
		end
	end
	-- Discard constructor data.
	self.shapeData = nil
	self.bodyData = nil
	self.inherit = nil
end

function Body.final(self)
	self.body:destroy()
end

function Body.set(self, type, x, y, angle, shapes, body_prop, ignore_parent_transform)
	Body.super.set(self, x, y, angle)
	local rand = love.math.random
	self.color = {rand()*0.8+0.2, rand()*0.8+0.2, rand()*0.8+0.2, 1}
	self.type = type
	if self.type ~= 'kinematic' then
		self.updateTransform = Object.TRANSFORM_ABSOLUTE
	end
	-- Save to use on init:
	self.shapeData = shapes
	self.bodyData = body_prop
	self.ignore_transform = ignore_parent_transform
end

return Body
