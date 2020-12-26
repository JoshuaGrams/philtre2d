local Random = {}

local rnd = math.random

function Random.range(lo, hi)
	return lo + (hi - lo) * rnd()
end

function Random.near(center, diff)
	return center - diff + 2 * diff * rnd()
end

function Random.box(cx, cy, w, h)
	local x, y = rnd() - 0.5, rnd() - 0.5
	return { x = cx + x * w, y = cy + h * y }
end

-- There's about a 79% chance (pi/4) of the point falling in the disc,
-- so this is actually reasonably efficient, and it gives a uniform
-- spatial distribution over the disc.
function Random.disc(cx, cy, r)
	local x, y
	repeat
		x, y = 2 * (rnd() - 0.5), 2 * (rnd() - 0.5)
	until x * x + y * y <= 1
	return { x = cx + r * x, y = cy + r * y }
end

return Random
