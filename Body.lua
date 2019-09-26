local base = (...):gsub('[^%.]+$', '')
local matrix = require(base .. 'matrix')
local Object = require(base .. 'Object')
local World = require(base .. 'World')

local Body = Object:extend()

Body.className = 'Body'

function Body.draw(self)
	-- physics debug
	self.color[4] = self.body:isAwake() and 1 or 0.5
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
	if self.type == 'kinematic' or self.type == 'trigger' then
		-- User-Controlled - update physics body to match scene-tree Object.
		local newx, newy = self.parent:toWorld(self.pos.x, self.pos.y)
		local th, sx, sy = matrix.parameters(self.parent._to_world)
		local last = self.lastTransform
		self.body:setPosition(newx, newy)
		self.body:setAngle(self.angle + th)
		self.body:setLinearVelocity(0, 0) -- Just to make sure this can't build up.
	 	-- Bodies can't scale, set to inverted _to_world scale to enforce this.
		self.sx, self.sy = 1/sx, 1/sy
		-- Need to wake up the body if it's parent changes (or any ancestor).
		if newx ~= last.x or newy ~= last.y or th ~= last.angle then
			self.body:setAwake(true)
		end
		last.x, last.y, last.angle = newx, newy, th
	else -- 'dynamic' or 'static'
		-- Physics-Controlled - update scene-tree Object to match physics body.
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
	if self.type == 'trigger' then  f:setSensor(true)  end
end

function Body.init(self)
	-- By default, dynamic and static bodies are created in local coords.
	if not self.ignore_transform then
		if self.type == 'dynamic' or self.type == 'static' then
			self.pos.x, self.pos.y = self.parent:toWorld(self.pos.x, self.pos.y)
			self.angle = self.angle + matrix.parameters(self.parent._to_world)
		end
	end

	local world = getWorld(self.parent)
	self.world = world
	if not world then
		error('Body.init ' .. tostring(self) .. ' - No parent World found. Bodies must be descendants of a World object.')
	end
	-- Make body.
	local bType = (self.type == 'trigger') and 'dynamic' or self.type
	self.body = love.physics.newBody(world, self.pos.x, self.pos.y, bType)
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
	if self.type == 'dynamic' or self.type == 'static' then
		self.updateTransform = Object.TRANSFORM_ABSOLUTE
	else
		self.lastTransform = {}
		-- Fix rotation on kinematic and trigger bodies to make sure it can't go crazy.
		if body_prop then  body_prop.fixedRot = true
		else  body_prop = { fixedRot = true }  end
	end
	-- Save to use on init:
	self.shapeData = shapes
	self.bodyData = body_prop
	self.ignore_transform = ignore_parent_transform
end

return Body
