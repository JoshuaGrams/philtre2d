
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

local queryResults = {}

local function boxQueryCallback(fixture)
	table.insert(queryResults, fixture)
	return true
end

local function touchingBox(lt, rt, top, bot, world)
	for i, v in ipairs(queryResults) do  queryResults[i] = nil  end
	world:queryBoundingBox(lt, top, rt, bot, boxQueryCallback)
	if #queryResults > 0 then -- Return table if results, or nil if none.
		return queryResults
	end
end

local function atPoint(x, y, world)
	for i, v in ipairs(queryResults) do  queryResults[i] = nil  end
	world:queryBoundingBox(x-0.5, y-0.5, x+0.5, y+0.5, boxQueryCallback)
	for i=#queryResults, 1, -1 do
		local fixture = queryResults[i]
		if not fixture:testPoint(x, y) then
			table.remove(queryResults, i)
		end
	end
	if #queryResults > 0 then -- Return table if results, or nil if none.
		return queryResults
	end
end

local function getWorld(self)
	local parent = self.parent
	if not parent then
		return
	elseif parent.is and parent:is(World) and parent.world then
		return parent.world
	else
		return getWorld(parent)
	end
end

return {
	setCategories = setCategories, categories = categories,
	categoriesExcept = categoriesExcept, categoryIndex = categoryIndex,
	atPoint = atPoint, touchingBox = touchingBox, getWorld = getWorld,
}
