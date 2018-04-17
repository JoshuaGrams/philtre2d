require('engine.all')
local Bezier = require('engine.bezier')
local BezierCommands = require('bezier-commands')

local History = require('history')


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
	BezierCommands:init(edits, 'bezier')

	love.graphics.setLineWidth(3)
end

local function splineCoords(curve, tolerance)
	local points = Bezier.splineToPolyline(curve, tolerance)
	local coords = {}
	for _,p in ipairs(points) do
		table.insert(coords, p[1])
		table.insert(coords, p[2])
	end
	return coords
end

local function drawCurve(curve, tolerance, focused)
	local coords = splineCoords(curve, tolerance)
	if coords then love.graphics.line(coords) end

	if not focused then return end

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

function love.draw()
	drawCurve(curve, 0.5, true)
end

function love.mousemoved(x, y)
	if dragging then
		edits:update(curve, dragging, x, y)
	else
		local i, d = Bezier.nearestControlPoint(curve, x, y)
		if i and d <= pickDistance then
			curve.highlight = i
		else
			curve.highlight = false
		end
	end
end

function love.mousepressed(x, y, b)
	local n, d = Bezier.nearestControlPoint(curve, x, y)
	if d > pickDistance then n = false end
	if b == 1 then
		if n then
			dragging = n
			edits:perform('bezier.movePoint', curve, n, x, y)
		else
			edits:perform('bezier.extend', curve, x, y)
		end
	end
end

function love.mousereleased(x, y, b)
	if b == 1 and dragging then
		dragging = false
	end
end

local function toggleConstraint(curve, n)
	local e = Bezier.endpointIndex(n)
	if n ~= e or n == 1 or n == #curve then return end
	local ep = curve[e]
	local constraint
	if ep.constraint == 'smooth' then constraint = 'symmetric'
	elseif ep.constraint == 'symmetric' then constraint = nil
	else constraint = 'smooth' end
	edits:perform('bezier.enforce', curve, e, constraint)
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
				edits:perform('bezier.deleteSegment', curve, curve.highlight)
			end
		elseif k == 'c' then
			if curve.highlight then
				toggleConstraint(curve, curve.highlight)
			end
		end
	end
end
