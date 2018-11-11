
local collCategories = {} -- -- { [name] = index, ... }

local function setCategories(...)
	local c = {...}
	for i, v in ipairs(c) do
		if i > 16 then
			error("physics.setCategories - Can't have more than 16 collision categories.")
		elseif type(v) == 'string' then
			collCategories[v] = i
		else
			error('physics.setCategories - Invalid category name: ' .. v .. '. Category names must be strings.')
		end
	end
end

local function categories(...)
	local c = {...}
	for i, v in ipairs(c) do
		local ci = collCategories[v]
		if not ci then
			error('physics.categories - Category name "' .. v .. '" not recognized.')
		end
		c[i] = ci
	end
	return c
end

local function categoriesExcept(...)
	local not_c = {...}
	-- Add names as keys for easy checking.
	for i,v in ipairs(not_c) do  not_c[v] = true  end
	local c = {}
	for name,i in pairs(collCategories) do
		if not not_c[name] then  table.insert(c, i)  end
	end
	return c
end

local function categoryIndex(categoryName)
	return collCategories[categoryName]
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
	setCategories = setCategories, categories = categories,
	categoriesExcept = categoriesExcept, categoryIndex = categoryIndex
}
