local T = require 'lib.simple-test'

local Box = require 'engine.layout.Box'

return {
	"GUI Layout Box",
	{
		function()
			local box = Box(10, 50)
			T.has(box:request(), {w=10, h=50}, "request", "box")
		end,
	}
}
