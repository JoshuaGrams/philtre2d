
local T = require('engine.scene-tree')

local fix = {}
local paths = {}
local obj = {}
local coll_groups = {}

local function handleContact(s, type, a, b, hit, normImpulse, tanImpulse)
	fix[1], fix[2] = a, b -- index fixtures so we can flip them
	-- get object paths from fixtures' userData
	paths[1], paths[2] = a:getUserData(), b:getUserData()
	-- get objects from scene tree
	obj[1], obj[2] = s.tree:get(paths[1]), s.tree:get(paths[2])
	-- pass the call to each object and any scripts it has
	for i=1, 2 do
		local o = obj[i]
		if o then
			if o[type] then o[type](o, fix[i], fix[3-i], obj[3-i], hit, normImpulse, tanImpulse) end
			if o.script then
				for _, script in ipairs(o.script) do
					if script[type] then script[type](o, fix[i], fix[3-i], obj[3-i], hit, normImpulse, tanImpulse) end
				end
			end
		else
			print(type .. ' - "' .. paths[i] .. '" does not exist')
		end
	end
end

local function update(s, dt)
	s.world:update(dt)
end

local methods = { update = update }
local class = { __index = methods }

local function make_callback(self, type)
	local cb = function(a, b, hit, normImpulse, tangImpulse)
		handleContact(self, type, a, b, hit, normImpulse, tangImpulse)
	end
	return cb
end

local function new(xg, yg, sleep, disableBegin, disableEnd, disablePre, disablePost)
	local s = T.object()
	s.world = love.physics.newWorld(xg, yg, sleep)
	s.world:setCallbacks(
		not disableBegin and make_callback(s, 'beginContact') or nil,
		not disableEnd and make_callback(s, 'endContact') or nil,
		not disablePre and make_callback(s, 'preSolve') or nil,
		not disablePost and make_callback(s, 'postSolve') or nil
	)
	return setmetatable(s, class)
end


local function set_groups(...)
	local g = {...}
	for i, v in ipairs(g) do
		if i > 16 then
			error("physics.set_groups - Can't have more than 16 collision groups.")
		elseif type(v) == 'string' then
			coll_groups[v] = i
		else
			error('physics.set_groups - Invalid group name: ' .. v .. '. Group names must be strings.')
		end
	end
end

local function groups(...)
	local g = {...}
	for i, v in ipairs(g) do
		local gi = coll_groups[v]
		if not gi then
			error('physics.groups - Group name "' .. v .. '" not recognized.')
		end
		g[i] = gi
	end
	return g
end

return { new = new, set_groups = set_groups, groups = groups }
