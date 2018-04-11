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

local function extendBezierWith(curve, cp1, cp2, ep)
	table.insert(curve, cp1)
	table.insert(curve, cp2)
	table.insert(curve, ep)
end

local function moveBezierPoint(curve, n, x, y)
	local p = curve[n]
	local undoX, undoY = p[1], p[2]
	p[1], p[2] = x, y
	return curve, n, undoX, undoY
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
	edits:command('retractBezier', retractBezier, extendBezierWith)
	edits:command('moveBezierPoint', moveBezierPoint, moveBezierPoint, moveBezierPoint)

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
	elseif b == 2 then
		edits:perform('retractBezier', curve)
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
		if k == 'escape' then love.event.quit() end
	end
end
