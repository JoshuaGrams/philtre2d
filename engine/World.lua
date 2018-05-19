
local scene = require 'engine.scene-tree'
local Object = require 'engine.Object'

local World = Object:extend()

World.className = 'World'

local fix = {}
local obj = {}

local function handleContact(type, a, b, hit, normImpulse, tanImpulse)
	fix[0], fix[1] = a, b -- Index fixtures so we can flip them easily.
	obj[0], obj[1] = a:getUserData(), b:getUserData()
	-- Pass the call to both objects and any scripts they have. (using Object.call)
	for i=0,1 do
		local o = obj[i]
		--print(type, "\n", o, "\n", obj[1-i], "\n", fix[i], fix[1-i], hit, normImpulse, tanImpulse)
		if o then
			-- First fixture is the `self` fixture, second is the `other` fixture.
			o:call(type, fix[i], fix[1-i], obj[1-i], hit, normImpulse, tanImpulse)
		else
			print(type .. ' - WARNING: Object "' .. obj[i] .. '" does not exist.')
		end
	end
end

local function makeCallback(self, type)
	-- Only postSolve actually uses the last two arguments.
	local cb = function(a, b, hit, normImp, tanImp)
		if self.isUpdating then
			-- Delay callbacks that happen during physics update, so bodies
			-- can be created during a callback.
			local t = { type = type, a = a, b = b, hit = hit, normImp = normImp, tanImp = tanImp }
			table.insert(self.delayedCallbacks, t)
		else
			-- Handle callbacks outside of physics update immediately, so
			-- endContact callbacks for deleted bodies will happen correctly.
			--		(They happen instantly when a body is destroyed.)
			handleContact(type, a, b, hit, normImpulse, tanImpulse)
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
			handleContact(cb.type, cb.a, cb.b, cb.hit, cb.normImp, cb.tanImp)
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
