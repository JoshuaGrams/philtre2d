
-- We represent vectors as arrays so we can have curves in
-- arbitrary numbers of dimensions.

local function lerp(t, a, b)
	local out = {}
	for i=1,#a do
		out[i] = a[i] + t * (b[i] - a[i])
	end
	return out
end

-- De Casteljau algorithm - return 7 points describing two
-- curves (the middle point is shared).  Note that this is also
-- a decent way to get a point on the curve (a little slower
-- than expanding the polynomial and computing the point
-- directly, but more numerically stable).
local function split(b, t)
	local n = 7
	local p = {}
	-- Endpoints remain the same.
	p[1] = b[1]
	p[n] = b[4]
	-- Interpolate between the four control points.
	local middle
	p[1+1] = lerp(t, b[1], b[2])
	middle = lerp(t, b[2], b[3])
	p[n-1] = lerp(t, b[3], b[4])
	-- Interpolate between the three new points.
	p[1+2] = lerp(t, p[1+1], middle)
	p[n-2] = lerp(t, middle, p[n-1])
	-- Interpolate between those two to get the point on the
	-- curve at `t`.
	p[1+3] = lerp(t, p[1+2], p[n-2])
	return p
end


-- Approximation Polyline

-- From Weiyin Ma and Renjiang Zhang's 2006 paper _Efficient
-- Piecewise Linear Approximation of Bezier Curves with Improved
-- Sharp Error Bound_.

-- Second-order difference of control vertices.
local function delta2(b, i)
	out = {}
	local p, q, r = b[i], b[i+1], b[i+2]
	for j=1,#p do
		out[j] = math.abs(p[j] - 2 * q[j] + r[j])
	end
	return out
end

local function error_bounds(b)
	local d2, a, b = 0, delta2(b, 1), delta2(b, 2)
	for i=1,#a do
		local n = math.max(a[i], b[i])
		d2 = d2 + n*n
	end
	return math.sqrt(d2) * 75 / 1024
end

-- Compute the approximation point corresponding to control
-- point `b` and label it with the given t-value.
local function point(a, b, c, d, t)
	local k = 1/32
	local out = {t=t}
	for i=1,#a do
		out[i] = k * (9*a[i] + 15*b[i] + 7*c[i] + d[i])
	end
	return out
end

-- Approximate curve with three line segments (four points).
-- The t-values are interpolated and attached to each point,
-- but are not otherwise used.
local function approximate(b, out, t0, t1)
	if #out > 0 then table.remove(out) end
	local ta, tb
	if t0 and t1 then
		ta, tb = t0*2/3 + t1*1/3, t0*1/3 + t1*2/3
	end
	table.insert(out, {t=t0, unpack(b[1])})
	table.insert(out, point(b[1], b[2], b[3], b[4], ta))
	table.insert(out, point(b[4], b[3], b[2], b[1], tb))
	table.insert(out, {t=t1, unpack(b[4])})
	return out
end

local function toPolyline(b, e, out, t0, t1)
	out = out or {}
	-- Do three line segments adequately approximate `b`?
	if error_bounds(b) < e then
		return approximate(b, out, t0, t1)
	else
		-- Split it in half and approximate both halves.
		local tc = (t0 and t1) and (t0+t1)/2
		local b0 = split(b, 0.5)
		local b1 = {unpack(b0, 4)}
		out = toPolyline(b0, e, out, t0, tc)
		return toPolyline(b1, e, out, tc, t1)
	end
	return out
end

-- Is the x-value of the curve always increasing (derivative
-- positive)? Find the places where the derivative B' crosses
-- zero by converting it to the form t^2 + 2bt + c = 0
-- and completing the square.
--
-- B'(t) = (p2-p1)3(1-t)^2 + (p3-p2)6(1-t)t + (p4-p3)3t^2
local function xAlwaysIncreasing(b)
	local dx1 = b[2].x - b[1].x
	local dx2 = b[3].x - b[2].x
	local dx3 = b[4].x - b[3].x
	if dx1 <= 0 or dx3 <= 0 then return false end  -- check endpoints
	-- concave down, so it doesn't go below zero in the middle.
	local a = dx3 - 2*dx2 + dx1
	if a <= 0 then return true end
	-- crosses 0 outside the [0..1] range.
	local b = (dx1 - dx2) / a
	-- No 0-crossings (or 1 at -b), or only at t > 1.
	if b < 0 or b > 1 then return true end
	local d = b*b - dx1/a  -- discriminant: b^2 - c
	return d < 0 or d > (1-b)*(1-b)
end

return {
	split = split,
	toPolyline = toPolyline,
	xAlwaysIncreasing = xAlwaysIncreasing
}
