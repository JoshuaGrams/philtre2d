local T = require 'lib.simple-test'

local Layout = require 'engine.layout'

return {
	"GUI Layout",
	{
		function()
			local box = Layout.Box.new(10, 50)
			local req = box:request()
			T.is(req.w, 10, "box width request")
			T.is(req.h, 50, "box height request")
		end,
		function()
			local row = Layout.Row.new(0, false, {
				{ Layout.Box.new(10, 50) },
				{ Layout.Box.new(15, 49) }
			})
			local req = row:request()
			T.is(req.w, 25, "row width request")
			T.is(req.h, 50, "row height request")
		end,
		function()
			local row = Layout.Row.new(5, false, {
				{ Layout.Box.new(10, 50) },
				{ Layout.Box.new(15, 50), 'end' },
				{ Layout.Box.new(10, 50) }
			})
			local req = row:request()
			T.is(req.w, 45, "row width request (spacing)")
			T.is(req.h, 50, "row height request (spacing)")
		end
	}
}
