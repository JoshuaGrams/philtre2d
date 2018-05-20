
local coll_groups = {} -- -- { [name] = index, ... }

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

local function groups_except(...)
	local not_g = {...}
	-- Add names as keys for easy checking.
	for i,v in ipairs(not_g) do  not_g[v] = true  end
	local g = {}
	for name,i in pairs(coll_groups) do
		if not not_g[name] then  table.insert(g, i)  end
	end
	return g
end

local function group_index(group_name)
	return coll_groups[group_name]
end
-- ray cast
	-- multi-hit - sorted near-to-far
	-- only-closest?

-- point check
	-- use world:queryBoundingBox
		-- assemble a fixture list
	-- do fixture:testPoint on each fixture
		-- and eliminate any misses

return {
	set_groups = set_groups, groups = groups,
	groups_except = groups_except, group_index = group_index
}
