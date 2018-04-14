local Bezier = require 'engine.bezier'

local lerp = Bezier.v.lerp

local function extend(curve, x, y)
	local endpoint = {x, y}
	if #curve > 0 then
		local beginpoint = curve[#curve]
		table.insert(curve, lerp(1/3, beginpoint, endpoint))
		table.insert(curve, lerp(2/3, beginpoint, endpoint))
	end
	table.insert(curve, endpoint)
	return curve
end

local function retract(curve)
	local cp1 = table.remove(curve)
	local cp2 = table.remove(curve)
	local ep = table.remove(curve)
	return curve, cp1, cp2, ep
end

local function enforce(curve, n, constraint)
	local p, ep, q = curve[n-1], curve[n], curve[n+1]
	local c = ep.constraint or false
	local oldP, oldQ = {unpack(p)}, {unpack(q)}
	Bezier.enforceConstraint(curve, n, constraint)
	return curve, n, c, oldP, oldQ
end

local function undoConstraint(curve, e, c, cp1, cp2)
	local p, ep, q = curve[e-1], curve[e], curve[e+1]
	p[1], p[2] = unpack(cp1)
	ep.constraint = c
	q[1], q[2] = unpack(cp2)
end

local function movePoint(curve, n, x, y)
	local p = curve[n]
	local oldX, oldY = p[1], p[2]
	Bezier.movePoint(curve, n, x, y)
	return curve, n, oldX, oldY
end

local function deleteSegment(curve, n)
	return curve, Bezier.deleteSegment(curve, n, true)
end

local function insertSegment(curve, n, points)
	for i,p in ipairs(points) do
		table.insert(curve, n+(i-1), p)
	end
end

local function init(self, history, prefix)
	prefix = prefix and prefix .. '.' or ''
	for name,cmd in pairs(self.commands) do
		history:command(prefix .. name, unpack(cmd))
	end
end

return {
	init = init,
	commands = {
		extend = { extend, retract },
		enforce = { enforce, undoConstraint },
		movePoint = { movePoint, movePoint, movePoint },
		deleteSegment = { deleteSegment, insertSegment },
	}
}
