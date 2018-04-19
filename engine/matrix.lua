local M = {}

M.identity = {
	ux = 1, uy = 0,
	vx = 0, vy = 1,
	x = 0, y = 0
}

-- Since the order matters, this is the equivalent of skewing,
-- scaling, rotating, then translating.
M.matrix = function(x, y, radians, sx, sy, kx, ky, m)
	sx, kx = sx or 1, kx or 0
	sy, ky = sy or sx, ky or 0
	radians = radians or 0
	local cos, sin = math.cos(radians), math.sin(radians)
	local sy_kx, sx_ky = sy*kx, sx*ky

	m = m or {}
	m.ux, m.uy = cos*sx - sin*sy_kx, sin*sx + cos*sy_kx
	m.vx, m.vy = -sin*sy + cos*sx_ky, cos*sy + sin*sx_ky
	m.x, m.y = x, y
	return m
end

-- Create a duplicate matrix or set a matrix to be equal.
M.copy = function(m, out)
	out = out or {}
	out.ux = m.ux;  out.uy = m.uy
	out.vx = m.vx;  out.vy = m.vy
	out.x = m.x;  out.y = m.y
	return out
end

-- Transform vector (multiply `v * m`, so transforms happen in
-- left-to-right order when you combine matrices).
M.x = function(m, x, y, w)
	w = w or 1
	local x2 = x * m.ux + y * m.vx + w * m.x
	local y2 = x * m.uy + y * m.vy + w * m.y
	return x2, y2
end

-- Multiply matrices `m * n`
M.xM = function(m, n, out)
	-- Save all values in case `out` is `m` or `n`.
	local m_ux, m_uy, n_ux, n_uy = m.ux, m.uy, n.ux, n.uy
	local m_vx, m_vy, n_vx, n_vy = m.vx, m.vy, n.vx, n.vy
	local  m_x,  m_y,  n_x,  n_y =  m.x,  m.y,  n.x,  n.y

	out = out or {}
	out.ux = m_ux * n_ux + m_uy * n_vx -- + 0 * n_x
	out.uy = m_ux * n_uy + m_uy * n_vy -- + 0 * n_y
	out.vx = m_vx * n_ux + m_vy * n_vx -- + 0 * n_x
	out.vy = m_vx * n_uy + m_vy * n_vy -- + 0 * n_y
	out.x =   m_x * n_ux +  m_y * n_vx + n_x
	out.y =   m_x * n_uy +  m_y * n_vy + n_y
	return out
end

M.invert = function(m, out)
	local d = m.ux * m.vy - m.uy * m.vx  -- 2x2 determinant
	if math.abs(d) < 0.0001 then return false end

	out = out or {}
	local m_ux = m.ux
	local k = 1/d
	out.ux, out.uy = m.vy*k, -m.uy*k
	out.vx, out.vy = -m.vx*k, m_ux*k
	-- Use new values to compute *inverse* transform of -origin.
	local x, y = m.x, m.y
	out.x = -x * out.ux - y * out.vx
	out.y = -x * out.uy - y * out.vy
	return out
end

M.parameters = function(m)
	-- Return values: angle, scale, skew
	-- Note that origin can be read directly from matrix.
	local th, sx, sy, kx, ky = 0, 0, 0, 0, 0

	local tiny = 0.00001
	local u2 = m.ux * m.ux  +  m.uy * m.uy
	if u2 < tiny then
		local v2 = m.vx * m.vx  +  m.vy * m.vy
		if v2 >= tiny then
			th = math.atan2(-m.vx, m.vy)
			sy = math.sqrt(v2)
		end
	else  -- normal case
		th = math.atan2(m.uy, m.ux)
		sx = math.sqrt(u2)
		sy = (m.ux * m.vy - m.uy * m.vx) / sx
		ky = (m.ux * m.vx + m.uy * m.vy) / u2
	end
	return th, sx, sy, kx, ky
end

return M
