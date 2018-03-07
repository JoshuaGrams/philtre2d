
local scene -- scene-tree ref from user
local paths = {}
local obj = {}

local function handleContact(type, a, b, hit, normImpulse, tanImpulse)
	-- get object paths from fixtures' userData
	paths[1], paths[2] = a:getUserData(), b:getUserData()
	-- get objects from scene tree
	obj[1], obj[2] = scene:get(paths[1]), scene:get(paths[2])
	-- pass the call to each object and any scripts it has
	for i=1, 2 do
		local o = obj[i]
		if o then
			if o[type] then o[type](o, a, b, hit, normImpulse, tanImpulse) end
			if o.script then
				for i, script in ipairs(o.script) do
					if script[type] then script[type](o, a, b, hit, normImpulse, tanImpulse) end
				end
			end
		else
			print(type .. ' - "' .. paths[i] .. '" does not exist')
		end
	end
end

local function beginContact(a, b, hit)
	handleContact('beginContact', a, b, hit)
end

local function endContact(a, b, hit)
	handleContact('endContact', a, b, hit)
end

local function preSolve(a, b, hit)
	handleContact('preSolve', a, b, hit)
end

local function postSolve(a, b, hit, normImpulse, tangImpulse)
	handleContact('postSolve', a, b, hit, normImpulse, tangImpulse)
end

local function init(xg, yg, sleep, scene_tree, disableBegin, disableEnd, disablePre, disablePost)
	scene = scene_tree
	local world = love.physics.newWorld(xg, yg, sleep)
	-- by default all callbacks are enabled
	world:setCallbacks(
		not disableBegin and beginContact or nil,
		not disableEnd and endContact or nil,
		not disablePre and preSolve or nil,
		not disablePost and postSolve or nil
	)
	return world
end

-- if init world is called before scene-tree is created (it probably is),
-- call this afterward to update our scene-tree reference
local function set_scene(scene_tree)
	scene = scene_tree
end

return { init = init, set_scene = set_scene }
