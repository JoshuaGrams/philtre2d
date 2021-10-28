local base = (...):gsub('objects%.Body$', '')
local matrix = require(base .. 'modules.matrix')
local physics = require(base .. 'modules.physics')
local Object = require(base .. 'objects.Object')

local Body = Object:extend()

Body.className = 'Body'

local FULL_MASK_INT = 2^16 - 1
local SLEEPING_ALPHA_MULT = 0.5
local FILL_ALPHA_MULT = 0.3
local SENSOR_ALPHA_MULT = 0.35

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
		local sensorAlphaMult = f:isSensor() and SENSOR_ALPHA_MULT or 1
		love.graphics.setColor(r, g, b, alpha * sensorAlphaMult)
		local s = f:getShape()
		local shapeType = s:getType()
		if shapeType == 'circle' then
			local x, y = s:getPoint()
			love.graphics.circle('line', x, y, s:getRadius(), 24)
			love.graphics.setColor(r, g, b, alpha * FILL_ALPHA_MULT * sensorAlphaMult)
			love.graphics.circle('fill', x, y, s:getRadius(), 24)
		elseif shapeType == 'edge' or shapeType == 'chain' then
			local points = {s:getPoints()}
			love.graphics.line(points)
		else
			local points = {s:getPoints()}
			love.graphics.polygon('line', points)
			love.graphics.setColor(r, g, b, alpha * FILL_ALPHA_MULT * sensorAlphaMult)
			love.graphics.polygon('fill', points)
		end
	end
end

function Body.debugDraw(self, layer)
	self.tree.draw_order:addFunction(layer, self._to_world, debugDraw, self)
end

function Body.TRANSFORM_DYNAMIC_PHYSICS(s)
	s.pos.x, s.pos.y = s.body:getPosition()
	s.angle = s.body:getAngle()
	s._to_world = matrix.new(s.pos.x, s.pos.y, s.angle, 1, 1, 0, 0, s._to_world) -- Don't allow scale or shear.
	s._to_local = nil
end

function Body.TRANSFORM_KINEMATIC_PHYSICS(s)
	local wx, wy = s.parent:toWorld(s.pos.x, s.pos.y)
	local wAngle = s.angle + matrix.parameters(s.parent._to_world)
	s.body:setPosition(wx, wy)
	s.body:setAngle(wAngle)
	-- Need to wake up the body if it's parent changes (or any ancestor).
	local last = s.lastTransform
	if wx ~= last.x or wy ~= last.y or wAngle ~= last.angle then
		s.body:setAwake(true)
	end
	last.x, last.y, last.angle = wx, wy, wAngle
	-- Already transformed pos & angle to world space, don't allow scale or shear.
	s._to_world = matrix.new(wx, wy, wAngle, 1, 1, 0, 0, s._to_world)
	s._to_local = nil
end

local body_set_funcs = {
	linDamp = 'setLinearDamping',
	angDamp = 'setAngularDamping',
	bullet = 'setBullet',
	fixedRot = 'setFixedRotation',
	gScale = 'setGravityScale'
}

local shape_constructors = {
	circle = love.physics.newCircleShape, -- radius OR x, y radius
	rectangle = love.physics.newRectangleShape, -- width, height OR x, y, width, height, angle
	polygon = love.physics.newPolygonShape, -- x1, y1, x2, y2, x3, y3, ... - up to 8 verts
	edge = love.physics.newEdgeShape, -- x1, y1, x2, y2
	chain = love.physics.newChainShape, -- loop, points OR loop, x1, y1, x2, y2 ... no vert limit
}

function Body.addFixture(self, data)
	-- data[1] = shape type, data[2] = shape specs, any other keys = fixture props.
	local shape = shape_constructors[data[1]](unpack(data[2]))
	local density, sensor = data.density, data.sensor
	if self.type == 'trigger' then
		density = density or 0
		sensor = true
	end
	local f = love.physics.newFixture(self.body, shape, density)
	f:setUserData(self) -- Store self ref on each fixture for collision callbacks.

	local cat = data.categories or 1
	local mask = data.mask or FULL_MASK_INT
	local group = data.group or 0
	f:setFilterData(cat, mask, group) -- With bitmasks, can only set them all together, not individually.

	if sensor then  f:setSensor(sensor)  end
	if data.friction then  f:setFriction(data.friction)  end
	if data.restitution then  f:setRestitution(data.restitution)  end

	return f
end

function Body.init(self)
	self.world = physics.getWorld(self)
	if not self.world then
		error('Body.init (' .. tostring(self.path) .. ') - No parent World found. Bodies must be descendants of a World object.')
	end

	-- By default, dynamic and static bodies are created in local coords.
	if not self._ignoreTransform then
		if self.type == 'dynamic' or self.type == 'static' then
			self.pos.x, self.pos.y = self.parent:toWorld(self.pos.x, self.pos.y)
			self.angle = self.angle + matrix.parameters(self.parent._to_world)
		end
	end
	-- Make body.
	local bType = (self.type == 'trigger') and 'dynamic' or self.type
	self.body = love.physics.newBody(self.world, self.pos.x, self.pos.y, bType)
	self.body:setAngle(self.angle)
	if self._bodyData then
		for k,v in pairs(self._bodyData) do
			if body_set_funcs[k] then self.body[body_set_funcs[k]](self.body, v) end
		end
	end
	-- Make shapes & fixtures.
	if type(self._shapeData[1]) == 'string' then -- Only one fixture def.
		self:addFixture(self._shapeData)
	else
		for i, data in ipairs(self._shapeData) do -- A list of fixture defs.
			self:addFixture(data)
		end
	end

	if self.type == 'dynamic' or self.type == 'static' then
		self.updateTransform = Body.TRANSFORM_DYNAMIC_PHYSICS
	else
		self.updateTransform = Body.TRANSFORM_KINEMATIC_PHYSICS
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
		-- Doesn't have a body until init, so can't use the physics updateTransform.
		self.updateTransform = Object.TRANSFORM_ABSOLUTE
	else
		-- self.updateTransform == normal object transform (already inherited).
		self.lastTransform = {}
		-- Fix rotation on kinematic and trigger bodies to make sure it can't go crazy.
		if body_prop then  body_prop.fixedRot = true
		else  body_prop = { fixedRot = true }  end
	end
	-- Save to use on init:
	self._shapeData = shapes
	self._bodyData = body_prop
	self._ignoreTransform = ignore_parent_transform
end

return Body
