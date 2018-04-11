require('engine.all')
local Bezier = require('engine.bezier')

local History = require('history')


----------------------------------------------------------------
-- Vector math on arrays of arbitrary size.

local function lerp(t, a, b)
	local out = {}
	for i=1,#a do out[i] = a[i] + t * (b[i] - a[i]) end
	return out
end

local function distanceSquared(a, b)
	local d2 = 0
	for i=1,#a do
		local dx = b[i] - a[i]
		d2 = d2 + dx*dx
	end
	return d2
end


----------------------------------------------------------------
-- Curve commands.

local function isEndpoint(n)
	return n % 3 == 1
end

local function endpointIndex(n)
	return 1 + 3 * math.floor(n / 3)
end

local function otherControlPoint(curve, n)
	local cp = 2*endpointIndex(n) - n
	if cp < 1 or cp > #curve then cp = false end
	return cp
end

local function extendBezier(curve, x, y)
	local endpoint = {x, y}
	if #curve > 0 then
		local beginpoint = curve[#curve]
		table.insert(curve, lerp(1/3, beginpoint, endpoint))
		table.insert(curve, lerp(2/3, beginpoint, endpoint))
	end
	table.insert(curve, endpoint)
	return curve
end

local function retractBezier(curve)
	local cp1 = table.remove(curve)
	local cp2 = table.remove(curve)
	local ep = table.remove(curve)
	return curve, cp1, cp2, ep
end

local function moveControlPoints(curve, n, dx, dy)
	if n < #curve then
		local cp = curve[n+1]
		cp[1] = cp[1] + dx
		cp[2] = cp[2] + dy
	end
	if n > 1 then
		local cp = curve[n-1]
		cp[1] = cp[1] + dx
		cp[2] = cp[2] + dy
	end
end

local function moveOtherControlPoint(curve, n, dx, dy)
	local e = endpointIndex(n)
	local p, ep = curve[n], curve[e]
	local constraint = ep.constraint
	local o = curve[otherControlPoint(curve, n)]
	if constraint == 'smooth' then
		local ax, ay = p[1] - ep[1], p[2] - ep[2]
		local bx, by = o[1] - ep[1], o[2] - ep[2]
		local a2, b2 = ax*ax + ay*ay, bx*bx + by*by
		if a2 > 0.001 and b2 > 0.001 then
			local scale = math.sqrt(b2 / a2)
			o[1] = ep[1] - ax * scale
			o[2] = ep[2] - ay * scale
		end
	elseif constraint == 'symmetric' then
		o[1] = 2*ep[1] - p[1]
		o[2] = 2*ep[2] - p[2]
	end
end

local function setEndpointConstraint(curve, n, constraint)
	local e = endpointIndex(n)
	local p, ep, q = curve[e-1], curve[e], curve[e+1]
	-- Save old values
	local ret = { curve, e, ep.constraint, {unpack(p)}, {unpack(q)} }

	-- Offset of each point.
	local px, py = p[1] - ep[1], p[2] - ep[2]
	local qx, qy = q[1] - ep[1], q[2] - ep[2]
	-- Flip them in the same direction and average them.
	local dx, dy = 0.5 * (px - qx), 0.5 * (py - qy)
	-- Lengths of the above.
	local p2 = px*px + py*py
	local q2 = qx*qx + qy*qy
	local d2 = dx*dx + dy*dy
	if d2 < 0.001 then
		if p2 < 0.001 then
			if q2 < 0.001 then return  -- everything is zero.
			else dx, dy, d2 = qx, qy, q2 end
		else dx, dy, d2 = px, py, p2 end
	end

	ep.constraint = constraint
	if constraint == 'smooth' then
		local ps = math.sqrt(p2 / d2)
		local qs = math.sqrt(q2 / d2)
		p[1], p[2] = ep[1] + dx * ps, ep[2] + dy * ps
		q[1], q[2] = ep[1] - dx * qs, ep[2] - dy * qs
	elseif constraint == 'symmetric' then
		p[1], p[2] = ep[1] + dx, ep[2] + dy
		q[1], q[2] = ep[1] - dx, ep[2] - dy
	end

	return unpack(ret)
end

local function undoConstraint(curve, e, c, cp1, cp2)
	local p, ep, q = curve[e-1], curve[e], curve[e+1]
	p[1], p[2] = unpack(cp1)
	ep.constraint = c
	q[1], q[2] = unpack(cp1, cp2)
end

local function toggleConstraint(curve, n)
	local e = endpointIndex(n)
	if n ~= e or n == 1 or n == #curve then return end
	local ep = curve[e]
	local constraint
	if ep.constraint == 'smooth' then constraint = 'symmetric'
	elseif ep.constraint == 'symmetric' then constraint = nil
	else constraint = 'smooth' end
	edits:perform('setEndpointConstraint', curve, n, constraint)
end

local function moveBezierPoint(curve, n, x, y)
	local p = curve[n]
	local undoX, undoY = p[1], p[2]
	p[1], p[2] = x, y
	if isEndpoint(n) then
		local dx, dy = x - undoX, y - undoY
		moveControlPoints(curve, n, dx, dy)
	else
		local e = endpointIndex(n)
		if curve[e].constraint and otherControlPoint(curve, n) then
			moveOtherControlPoint(curve, n, dx, dy)
		end
	end
	return curve, n, undoX, undoY
end

local function deleteBezierPoint(curve, n)
	n = endpointIndex(n)
	local a, b = math.max(n-1, 1), math.min(n+1, #curve)
	if a == 1 then b = math.min(b+1, #curve)
	elseif b == #curve then a = math.max(a-1, 1) end
	local deleted = {unpack(curve, a, b)}
	for i=0,b-a do table.remove(curve, a) end
	return curve, a, deleted
end

local function insertBezierPoint(curve, n, points)
	for i,p in ipairs(points) do
		table.insert(curve, n+(i-1), p)
	end
end

local function nearestPoint(curve, x, y)
	local q = {x, y}
	local nearest, dist2 = false, math.huge
	for i,p in ipairs(curve) do
		local d2 = distanceSquared(p, q)
		if d2 < dist2 then dist2, nearest = d2, i end
	end
	return nearest, math.sqrt(dist2)
end


----------------------------------------------------------------
-- Main love callbacks.

function love.load()
	pickDistance = 10
	curve = {
		highlight = false,
		{100, 100}, {133, 133}, {167, 167}, {200, 200}
	}
	dragging = false
	edits = History.new()
	edits:command('extendBezier', extendBezier, retractBezier)
	edits:command('moveBezierPoint', moveBezierPoint, moveBezierPoint, moveBezierPoint)
	edits:command('deleteBezierPoint', deleteBezierPoint, insertBezierPoint)
	edits:command('setEndpointConstraint', setEndpointConstraint, undoConstraint)

	love.graphics.setLineWidth(3)
end

function love.draw()
	if #curve >= 4 then
		local points = {}
		for i=1,#curve-3,3 do
			if i > 1 then table.remove(points) end
			local b = {unpack(curve, i, i+3)}
			Bezier.toPolyline(b, 0.5, points)
		end
		local coords = {}
		for _,p in ipairs(points) do
			table.insert(coords, p[1])
			table.insert(coords, p[2])
		end
		love.graphics.line(coords)
	end

	local lw = love.graphics.getLineWidth()
	local r = math.ceil(1.5 * lw)
	local q = false
	for i,p in ipairs(curve) do
		local x, y = unpack(p)
		local h = (i == curve.highlight) and 1.5 or 1
		love.graphics.circle('fill', x, y, r*h)
		if q and i % 3 ~= 0 then
			local w = love.graphics.getLineWidth()
			local c = {love.graphics.getColor()}
			local a = c[4]
			c[4] = c[4] / 2
			love.graphics.setLineWidth(1)
			love.graphics.setColor(c)
			love.graphics.line(q[1], q[2], x, y)
			c[4] = a
			love.graphics.setLineWidth(w)
			love.graphics.setColor(c)
		end
		q = p
	end
end

function love.mousemoved(x, y)
	if dragging then
		edits:update(curve, dragging, x, y)
	else
		local i, d = nearestPoint(curve, x, y)
		if i and d <= pickDistance then
			curve.highlight = i
		else
			curve.highlight = false
		end
	end
end

function love.mousepressed(x, y, b)
	local n, d = nearestPoint(curve, x, y)
	if d > pickDistance then n = false end
	if b == 1 then
		if n then
			dragging = n
			edits:perform('moveBezierPoint', curve, n, x, y)
		else
			edits:perform('extendBezier', curve, x, y)
		end
	end
end

function love.mousereleased(x, y, b)
	if b == 1 and dragging then
		dragging = false
	end
end

function love.keypressed(k, s)
	local ctrl = love.keyboard.isDown('lctrl', 'rctrl')
	local shift = love.keyboard.isDown('lshift', 'rshift')
	if ctrl then
		if k == 'z' then
			if(shift) then edits:redo() else edits:undo() end
		elseif k == 'y' then
			edits:redo()
		end
	else
		if k == 'escape' then love.event.quit()
		elseif k == 'delete' or k == 'backspace' then
			if curve.highlight then
				edits:perform('deleteBezierPoint', curve, curve.highlight)
			end
		elseif k == 'c' then
			if curve.highlight then
				toggleConstraint(curve, curve.highlight)
			end
		end
	end
end
