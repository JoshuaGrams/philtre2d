
local categoryIntFromName = {} -- { [name] = int, ... }
local FULL_MASK_INT = 2^16 - 1

-- Assign names to collision category bits. (1-16)
local function setCategoryNames(...)
	local c = {...}
	for i, v in ipairs(c) do
		if i > 16 then
			error("physics.setCategoryNames - Can't have more than 16 collision categories.")
		elseif type(v) == 'string' then
			categoryIntFromName[v] = 2^(i-1)
		else
			error('physics.setCategoryNames - Invalid category name: ' .. v .. '. Category names must be strings.')
		end
	end
end

-- Take up to 16 category names.
-- Return the matching bitmask.
local function getCategoriesBitmask(...)
	local c = {...}
	local bitmask = 0
	for i, v in ipairs(c) do
		local catInt = categoryIntFromName[v]
		if not catInt then
			error('physics.getCategoriesBitmask - Category name "' .. v .. '" not recognized.')
		end
		bitmask = bitmask + catInt
	end
	return bitmask
end

-- Take up to 16 category names.
-- Return the matching inverse bitmask.
local function getMaskBitmask(...)
	return bit.bxor(getCategoriesBitmask(...), FULL_MASK_INT)
end

-- Takes a bitmask and a category name.
-- Returns if the bitmask has that category enabled (true/false).
local function isInCategory(bitmask, category)
	local categoryBitmask = categoryIntFromName[category]
	return bit.band(bitmask, categoryBitmask) > 0
end

-- Takes two "category" and "mask" bitmask pairs.
-- Returns if they collide (true/false).
local function shouldCollide(catBitsA, maskBitsA, catBitsB, maskBitsB)
	return (bit.band(maskBitsA, catBitsB) ~= 0) and (bit.band(catBitsA, maskBitsB) ~= 0)
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
	setCategoryNames = setCategoryNames,
	getCategoriesBitmask = getCategoriesBitmask,
	getMaskBitmask = getMaskBitmask,
	isInCategory = isInCategory, shouldCollide = shouldCollide,
	atPoint = atPoint, touchingBox = touchingBox, getWorld = getWorld,
}
