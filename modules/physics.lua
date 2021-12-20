
local physics = {}

local categoryIntFromName = {} -- { [name] = int, ... }
local FULL_MASK_INT = 2^16 - 1

-- Assign names to collision category bits. (1-16)
function physics.setCategoryNames(...)
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

-- Take category names and return the matching bitmask.
-- Returns 0 if none are specified.
-- Breaks if given duplicate names.
local function getBitmask(...)
	local catNames = {...}
	local bits = 0
	for i,catName in ipairs(catNames) do
		local catInt = categoryIntFromName[catName]
		if not catInt then
			error('physics.getBitmask - Category name "' .. catName .. '" not recognized.')
		end
		bits = bits + catInt
	end
	return bits
end

local function getInvBitmask(...)
	return bit.bxor(getBitmask(...), FULL_MASK_INT)
end

physics.getCategoriesBitmask = getBitmask
physics.categories = getBitmask

physics.getMaskBitmask = getInvBitmask
physics.mask = getInvBitmask
physics.onlyHit = getBitmask
physics.dontHit = getInvBitmask

-- Takes a bitmask and a category name.
-- Returns if the bitmask has that category enabled (true/false).
function physics.isInCategory(bitmask, category)
	local categoryBitmask = categoryIntFromName[category]
	return bit.band(bitmask, categoryBitmask) > 0
end

-- Takes two "category" and "mask" bitmask pairs.
-- Returns if they collide (true/false).
function physics.shouldCollide(catsA, maskA, catsB, maskB)
	return (bit.band(maskA, catsB) ~= 0) and (bit.band(catsA, maskB) ~= 0)
end

local RAYCAST_MODES = { any = true, all = true, closest = true }
local DEFAULT_RAYCAST_MODE = 'closest'

local queryResults = {}
local queryCats, queryMask
local raycastResults
local raycastMode = DEFAULT_RAYCAST_MODE

local function boxQueryCallback(fixture)
	table.insert(queryResults, fixture)
	return true
end

function physics.touchingBox(lt, rt, top, bot, world)
	for i, v in ipairs(queryResults) do  queryResults[i] = nil  end
	world:queryBoundingBox(lt, top, rt, bot, boxQueryCallback)
	if #queryResults > 0 then -- Return table if results, or nil if none.
		return queryResults
	end
end

function physics.atPoint(x, y, world)
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

local function raycastCallback(fixture, x, y, xn, yn, fraction)
	if queryCats and queryMask then
		local cats, mask = fixture:getFilterData()
		local canHit = physics.shouldCollide(cats, mask, queryCats, queryMask)
		if not canHit then  return -1  end
	end
	if raycastMode == 'any' then
		raycastResults = true
		return 0
	elseif raycastMode == 'closest' then
		raycastResults = {
			fixture = fixture,
			x = x, y = y, xn = xn, yn = yn, fraction = fraction
		}
		return fraction
	else -- raycastMode == 'all'
		raycastResults = raycastResults or {}
		local hit = {
			fixture = fixture,
			x = x, y = y, xn = xn, yn = yn, fraction = fraction
		}
		table.insert(raycastResults, hit)
		return 1
	end
end

function physics.raycast(x1, y1, x2, y2, world, mode, categories, mask)
	raycastMode = mode or DEFAULT_RAYCAST_MODE
	assert(RAYCAST_MODES[raycastMode], 'physics.raycast - Invalid raycast mode: "' .. tostring(mode) .. '". Must be "any", "all", or "closest".')
	queryCats, queryMask = categories, mask
	raycastResults = nil
	world:rayCast(x1, y1, x2, y2, raycastCallback)
	return raycastResults
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
physics.getWorld = getWorld

return physics
