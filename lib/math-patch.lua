
local PI = math.pi
local TWO_PI = PI*2
local random = love.math.random -- or math.random
local floor = math.floor

math.round = function(x, interval)
	if interval then return floor(x / interval + 0.5) * interval end
	return floor(x + 0.5)
end

math.sign = function(x)
	return x >=0 and 1 or -1
end

math.clamp = function(x, min, max)
	return x > min and (x < max and x or max) or min
end

math.remap = function(val, min_in, max_in, min_out, max_out)
	local in_fract = (val - min_in)/(max_in - min_in)
	if min_out and max_out then
		return in_fract * (max_out - min_out) + min_out
	else
		return in_fract
	end
end

math.lerp = function(a, b, t)
	return a + (b - a) * t
end

math.lerpdt = function(a, b, s, dt)
	return a + (b - a) * (1 - 0.5^(dt*s))
end

math.angle_between = function(a, b)
	local a = a - b
	return (a + PI) % TWO_PI - PI
end

math.rand_range = function(min, max)
	return random() * (max - min) + min
end

math.rand_1_to_1 = function()
	return (random() - 0.5) * 2
end
