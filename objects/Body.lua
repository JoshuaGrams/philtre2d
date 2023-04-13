local base = (...):gsub('objects%.Body$', '')
local matrix = require(base .. 'core.matrix')
local physics = require(base .. 'core.physics')
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
	if self.tree and self.drawIndex then
		self.tree.drawOrder:addFunction(layer, self._toWorld, debugDraw, self)
	end
end

function Body.TRANSFORM_DYNAMIC_PHYSICS(s)
	s.pos.x, s.pos.y = s.body:getPosition()
	s.angle = s.body:getAngle()
	s._toWorld = matrix.new(s.pos.x, s.pos.y, s.angle, 1, 1, 0, 0, s._toWorld) -- Don't allow scale or shear.
	s._toLocal = nil
end

function Body.TRANSFORM_KINEMATIC_PHYSICS(s)
	local wx, wy = s.parent:toWorld(s.pos.x, s.pos.y)
	local wAngle = s.angle + matrix.parameters(s.parent._toWorld)
	s.body:setPosition(wx, wy)
	s.body:setAngle(wAngle)
	-- Need to wake up the body if it's parent changes (or any ancestor).
	local last = s.lastTransform
	if wx ~= last.x or wy ~= last.y or wAngle ~= last.angle then
		s.body:setAwake(true)
	end
	last.x, last.y, last.angle = wx, wy, wAngle
	-- Already transformed pos & angle to world space, don't allow scale or shear.
	s._toWorld = matrix.new(wx, wy, wAngle, 1, 1, 0, 0, s._toWorld)
	s._toLocal = nil
end

local bodySetFuncs = {
	linDamp = 'setLinearDamping',
	angDamp = 'setAngularDamping',
	bullet = 'setBullet',
	fixedRot = 'setFixedRotation',
	gScale = 'setGravityScale'
}

local shapeConstructors = {
	circle = love.physics.newCircleShape, -- radius OR x, y radius
	rectangle = love.physics.newRectangleShape, -- width, height OR x, y, width, height, angle
	polygon = love.physics.newPolygonShape, -- x1, y1, x2, y2, x3, y3, ... - up to 8 verts
	edge = love.physics.newEdgeShape, -- x1, y1, x2, y2
	chain = love.physics.newChainShape, -- loop, points OR loop, x1, y1, x2, y2 ... no vert limit
}

function Body.addFixture(self, data)
	-- data[1] = shape type, data[2] = shape specs, any other keys = fixture props.
	local shape = shapeConstructors[data[1]](unpack(data[2]))
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

	local bodyX, bodyY, bodyAngle = self.pos.x, self.pos.y, self.angle

	-- We need world coords for creating the physics body.
	if self.type == 'trigger' or self.type == 'kinematic' then -- Body types that transform like normal children.
		bodyX, bodyY = self.parent:toWorld(bodyX, bodyY)
		bodyAngle = bodyAngle + matrix.parameters(self.parent._toWorld)
	end

	-- Make body.
	local bodyType = (self.type == 'trigger') and 'dynamic' or self.type
	self.body = love.physics.newBody(self.world.world, bodyX, bodyY, bodyType)
	self.body:setAngle(bodyAngle)
	if self._bodyData then
		for k,v in pairs(self._bodyData) do
			if bodySetFuncs[k] then self.body[bodySetFuncs[k]](self.body, v) end
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
		self.updateTransform = self.TRANSFORM_DYNAMIC_PHYSICS
	else
		self.updateTransform = self.TRANSFORM_KINEMATIC_PHYSICS
	end
end

function Body.final(self)
	-- If the world was removed first, it will already be destroyed.
	if not self.body:isDestroyed() then  self.body:destroy()  end
	-- In case we re-add this Body to the tree, reset updateTransform to it's pre-init state.
	if self.type == 'dynamic' or self.type == 'static' then
		self.updateTransform = Object.TRANSFORM_ABSOLUTE
	else
		self.updateTransform = Object.updateTransform
	end
end

function Body.set(self, type, x, y, angle, shapes, bodyProps)
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
		if bodyProps then  bodyProps.fixedRot = true
		else  bodyProps = { fixedRot = true }  end
	end
	-- Save to use on init:
	self._shapeData = shapes
	self._bodyData = bodyProps
end

return Body
