local base = (...):gsub('[^%.]+.[^%.]+$', '')
local T = require(base .. 'lib.simple-test')
local Rnd = require(base .. 'random')


return {
	"Random Generation",
	function()
		local seed = os.time() + math.floor(1000*os.clock())
		seed = seed * seed % 1000000
		seed = seed * seed % 1000000
		math.randomseed(seed)
	end,
	function()
		local lo, hi = 5, 10
		for i=1,20 do
			local r = Rnd.range(lo, hi)
			T.ok(r >= lo, 'range ' .. i .. ': ' .. r .. ' >= ' .. lo)
			T.ok(r <= hi, 'range ' .. i .. ': ' .. r .. ' <= ' .. hi)
		end
	end,
	function()
		local center, diff = 10, 2
		local lo, hi = center - diff, center + diff
		for i=1,20 do
			local r = Rnd.near(center, diff)
			T.ok(r >= lo, 'near ' .. i .. ': ' .. r .. ' >= ' .. lo)
			T.ok(r <= hi, 'near ' .. i .. ': ' .. r .. ' <= ' .. hi)
		end
	end,
	function()
		local cx, cy, w, h = 9, 20, 5, 8
		local x0, x1 = cx - 0.5 * w, cx + 0.5 * w
		local y0, y1 = cy - 0.5 * h, cy + 0.5 * h
		for i=1,20 do
			local p = Rnd.box(cx, cy, w, h)
			T.ok(p.x >= x0, 'box ' .. i .. '.x: ' .. p.x .. ' >= ' .. x0)
			T.ok(p.x <= x1, 'box ' .. i .. '.x: ' .. p.x .. ' <= ' .. x1)
			T.ok(p.y >= y0, 'box ' .. i .. '.y: ' .. p.y .. ' >= ' .. y0)
			T.ok(p.y <= y1, 'box ' .. i .. '.y: ' .. p.y .. ' <= ' .. y1)
		end
	end,
	function()
		local cx, cy, r = 9, 20, 5
		for i=1,20 do
			local p = Rnd.disc(cx, cy, r)
			local dx, dy = p.x - cx, p.y - cy
			local d = math.sqrt(dx * dx + dy * dy)
			T.ok(d <= r, 'disc ' .. i .. ': ' .. p.x .. ', ' .. y .. ' (' .. d .. ') from center (radius ' .. r .. ')')
		end
	end
}
