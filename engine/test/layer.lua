local T = require 'lib.simple-test'

local Layer = require 'engine.layer'
local M = require 'engine.matrix'

local function recordCall(called, name)
	table.insert(called, name)
end

return {
	"Layers",
	setup = function()
		return M.identity
	end,
	function(m)
		local called = {}
		local layer = Layer()
		local names = { 'first', 'second', 'third', 'fourth' }
		for _,name in ipairs(names) do
			layer:addFunction(m, recordCall, called, name)
		end
		layer:draw()
		T.is(#called, #names, "called correct number of functions")
		T.has(called, names, "should call functions in order")

		called = {}
		layer:clear()
		layer:addFunction(m, recordCall, called, 'fifth')
		layer:addFunction(m, recordCall, called, 'sixth')
		layer:draw()
		T.is(#called, 2, "can have fewer functions after being cleared")
		T.has(called, {
			'fifth', 'sixth'
		}, "should call only new functions after being cleared")

		called = {}
		layer:clear()
		layer:addFunction(m, recordCall, called, 'seventh')
		layer:addFunction(m, recordCall, called, 'eighth')
		layer:addFunction(m, recordCall, called, 'ninth')
		layer:addFunction(m, recordCall, called, 'tenth')
		layer:addFunction(m, recordCall, called, 'eleventh')
		layer:addFunction(m, recordCall, called, 'twelfth')
		layer:draw()
		T.is(#called, 6, "can have more functions after being cleared")
		T.has(called, {
			'seventh', 'eighth', 'ninth',
			'tenth', 'eleventh', 'twelfth'
		}, "should call only new functions after being cleared")
	end
}
