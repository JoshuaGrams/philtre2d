local base = (...):gsub('[^%.]+$', '')
local scene = require(base .. 'scene-tree')
local Object = require(base .. 'Object')

local World = Object:extend()

World.className = 'World'

local COLOR_NORMAL_ENABLED = {0, 1, 1, 1}
local COLOR_NORMAL_DISABLED = {1, 0, 0, 1}
local COLOR_CONTACT_PT_1 = {1, 0, 0, 1}
local COLOR_CONTACT_PT_2 = {1, 0.5, 0, 1}
local SIZE_CONTACT_PT_1 = 5
local SIZE_CONTACT_PT_2 = 3
local COLOR_CONTACT_PTS_LINE = {1, 0, 1, 0.5}
local NORMAL_LENGTH = 25
local NORMAL_ARROW_LENGTH = 10
local NORMAL_ARROW_ANGLE = 0.5

local function vec2_rotate(ax, ay, phi)
	local c = math.cos(phi);  local s = math.sin(phi)
	return c * ax - s * ay, s * ax + c * ay
end

function World.draw(self) -- Debug drawing for contacts.
	for i,contact in ipairs(self.world:getContacts()) do
		local x1, y1, x2, y2 = contact:getPositions()
		local isEnabled = contact:isEnabled()
		if x1 then
			-- Draw normal line.
			local col = isEnabled and COLOR_NORMAL_ENABLED or COLOR_NORMAL_DISABLED
			love.graphics.setColor(col)
			local nx, ny = contact:getNormal()
			local l1, l2 = NORMAL_LENGTH, NORMAL_ARROW_LENGTH
			local endx, endy = x1 + nx*l1, y1 + ny*l1
			love.graphics.line(x1, y1, endx, endy)
			-- Draw normal arrow edges.
			local v1x, v1y = vec2_rotate(nx, ny, NORMAL_ARROW_ANGLE)
			local v2x, v2y = vec2_rotate(nx, ny, -NORMAL_ARROW_ANGLE)
			love.graphics.line(endx, endy, endx - v1x*l2, endy - v1y*l2)
			love.graphics.line(endx, endy, endx - v2x*l2, endy - v2y*l2)
			-- Draw contact point.
			love.graphics.setColor(COLOR_CONTACT_PT_1)
			love.graphics.setPointSize(SIZE_CONTACT_PT_1)
			love.graphics.points(x1, y1)
		end
		if x2 then -- Draw second contact point.
			love.graphics.setColor(COLOR_CONTACT_PT_2)
			love.graphics.setPointSize(SIZE_CONTACT_PT_2)
			love.graphics.points(x2, y2)
			if x1 then -- Both contact points exist, draw line between them.
				love.graphics.setColor(COLOR_CONTACT_PTS_LINE)
				love.graphics.line(x1, y1, x2, y2)
			end
		end
	end
end

local fix = {}
local obj = {}

local function handleContact(type, a, b, contact, normImpulse, tanImpulse)
	if a:isDestroyed() or b:isDestroyed() then
		return
	end
	fix[0], fix[1] = a, b -- Index fixtures so we can flip them easily.
	obj[0], obj[1] = a:getUserData(), b:getUserData()
	-- Pass the call to both objects and any scripts they have. (using Object.call)
	for i=0,1 do
		local o = obj[i]
		-- print(type, "\n", o, "\n", obj[1-i], "\n", fix[i], fix[1-i], contact, normImpulse, tanImpulse)
		if o then
			-- First fixture is the `self` fixture, second is the `other` fixture.
			o:call(type, fix[i], fix[1-i], obj[1-i], contact, normImpulse, tanImpulse)
		else
			print(type .. ' - WARNING: Object "' .. obj[i] .. '" does not exist.')
		end
	end
end

local function makeCallback(self, type)
	local cb
	-- Don't delay preSolve or postSolve.
	-- preSolve in particular is useless if delayed. If you want to disable the contact it must be done immediately.
	if type == 'preSolve' or type == 'postSolve' then
		cb = function(a, b, contact, normImp, tanImp)
			handleContact(type, a, b, contact, normImpulse, tanImpulse) -- Only postSolve actually uses the last two arguments.
		end
	else
		cb = function(a, b, contact, normImp, tanImp)
			if self.isUpdating then
				-- Delay callbacks that happen during physics update, so bodies can be created during a callback.
				local t = { type = type, a = a, b = b, contact = contact}
				table.insert(self.delayedCallbacks, t)
			else
				-- Handle callbacks outside of physics update immediately, so endContact callbacks for deleted bodies will happen correctly.
				--		(They happen instantly when a body is destroyed.)
				handleContact(type, a, b, contact)
			end
		end
	end
	return cb
end

function World.update(self, dt)
	self.isUpdating = true
	self.world:update(dt)
	self.isUpdating = false
	if #self.delayedCallbacks > 0 then
		for i,cb in ipairs(self.delayedCallbacks) do
			handleContact(cb.type, cb.a, cb.b, cb.contact, cb.normImp, cb.tanImp)
		end
		self.delayedCallbacks = {}
	end
end

function World.final(self)
	self.world:destroy()
end

function World.set(self, xg, yg, sleep, disableBegin, disableEnd, disablePre, disablePost)
	World.super.set(self)
	self.updateTransform = Object.TRANSFORM_PASS_THROUGH
	self.world = love.physics.newWorld(xg, yg, sleep)
	self.world:setCallbacks(
		not disableBegin and makeCallback(self, 'beginContact') or nil,
		not disableEnd and makeCallback(self, 'endContact') or nil,
		not disablePre and makeCallback(self, 'preSolve') or nil,
		not disablePost and makeCallback(self, 'postSolve') or nil
	)
	self.delayedCallbacks = {}
end

return World
