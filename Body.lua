local base = (...):gsub('[^%.]+$', '')
local matrix = require(base .. 'matrix')
local Object = require(base .. 'Object')
local World = require(base .. 'World')

local Body = Object:extend()

Body.className = 'Body'

local FULL_MASK_INT = 2^16 - 1
local SLEEPING_ALPHA_MULT = 0.5
local FILL_ALPHA_MULT = 0.3

local function debugDraw(self)
	-- We're modifying the alpha value multiple times, so separate these and do it non-destructively.
	local r, g, b, alpha = self.color[1], self.color[2], self.color[3], self.color[4]
	alpha = self.body:isAwake() and alpha or alpha * SLEEPING_ALPHA_MULT

	local cx, cy = self.body:getLocalCenter()

	love.graphics.setBlendMode('alpha')
	love.graphics.setColor(r, g, b, alpha)
	love.graphics.circle('fill', cx, cy, 3, 4) -- Diamond-shaped dot at center of mass
	love.graphics.line(cx, cy, cx + 10, cy + 0) -- X axis line to show rotation.

	for i,f in ipairs(self.body:getFixtures()) do
		love.graphics.setColor(r, g, b, alpha)
		local s = f:getShape()
		local shapeType = s:getType()
		if shapeType == 'circle' then
			local x, y = s:getPoint()
			love.graphics.circle('line', x, y, s:getRadius(), 24)
			love.graphics.setColor(r, g, b, alpha * FILL_ALPHA_MULT)
			love.graphics.circle('fill', x, y, s:getRadius(), 24)
		elseif shapeType == 'edge' or shapeType == 'chain' then
			local points = {s:getPoints()}
			love.graphics.line(points)
		else
			local points = {s:getPoints()}
			love.graphics.polygon('line', points)
			love.graphics.setColor(r, g, b, alpha * FILL_ALPHA_MULT)
			love.graphics.polygon('fill', points)
		end
	end
end

function Body.debugDraw(self, layer)
	self.tree.draw_order:addFunction(layer, self._to_world, debugDraw, self)
end

function Body.TRANSFORM_PHYSICS(self)
	self.pos.x, self.pos.y = self.body:getPosition()
	self.angle = self.body:getAngle()
	Object.TRANSFORM_ABSOLUTE(self)
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

local function makeFixture(self, data)
	-- data[1] = shape type, data[2] = shape specs, any other keys = fixture props.
	local shape = shape_constructors[data[1]](unpack(data[2]))
	if self.type == 'trigger' then
		data.density = data.density or 0
		data.sensor = true
	end
	local f = love.physics.newFixture(self.body, shape, data.density)
	data[1], data[2], data.density = nil, nil, nil -- Remove already used values.
	f:setUserData(self) -- Store self ref on each fixture for collision callbacks.

	data.categories = data.categories or 1
	data.mask = data.mask or FULL_MASK_INT
	data.group = data.group or 0
	f:setFilterData(data.categories, data.mask, data.group) -- With bitmasks, can only set them all together, not individually.
	data.categories, data.mask, data.group = nil, nil, nil -- Remove already used values.

	for k,v in pairs(data) do
		if fixture_set_funcs[k] then
			f[fixture_set_funcs[k]](f, v)
		else
			error('Body.init (' .. tostring(self.path) .. ') - Invalid fixture-data key: "' .. k .. '".')
		end
	end
end

function Body.init(self)
	local world = getWorld(self.parent)
	self.world = world
	if not world then
		error('Body.init (' .. tostring(self.path) .. ') - No parent World found. Bodies must be descendants of a World object.')
	end

	-- By default, dynamic and static bodies are created in local coords.
	if not self.ignore_transform then
		if self.type == 'dynamic' or self.type == 'static' then
			self.pos.x, self.pos.y = self.parent:toWorld(self.pos.x, self.pos.y)
			self.angle = self.angle + matrix.parameters(self.parent._to_world)
		end
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

	if self.type == 'dynamic' or self.type == 'static' then
		self.updateTransform = Body.TRANSFORM_PHYSICS
	end
end

function Body.final(self)
	-- If the world was removed first, it will already be destroyed.
	if not self.body:isDestroyed() then  self.body:destroy()  end
end

function Body.set(self, type, x, y, angle, shapes, body_prop, ignore_parent_transform)
	Body.super.set(self, x, y, angle)
	local rand = love.math.random
	self.color = {rand()*0.8+0.4, rand()*0.8+0.4, rand()*0.8+0.4, 1}
	self.type = type
	if self.type == 'dynamic' or self.type == 'static' then
		self.updateTransform = Object.TRANSFORM_ABSOLUTE -- Change to TRANSFORM_PHYSICS after body is created.
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
