local base = (...):gsub('[^%.]+.[^%.]+$', '')
local T = require(base .. 'lib.simple-test')
local DepthList = require(base .. 'render.depth-list')

local function logCall(obj)
	table.insert(obj.log, obj.name)
end

local function Logger(log, name)
	return {
		log = log, name = name, draw = logCall
	}
end

local function empty(list)
	for i=1,#list do list[i] = nil end
end

return {
	"Depth Lists",
	function()
		local called = {}
		local middle = Logger(called, 'middle')
		local list = DepthList({
			Logger(called, 'top'),
			middle,
			Logger(called, 'bottom')
		})
		list:draw()
		T.is(#called, 3, "call initial layers")
		T.has(called, {
			'bottom', 'middle', 'top'
		}, "call from bottom to top")
		empty(called)

		list:add(Logger(called, 'new top'), 'top')
		list:draw()
		T.is(#called, 4, "added at top")
		T.has(called, {
			'bottom', 'middle', 'top', 'new top'
		}, "calls all 4 layers")
		empty(called)

		list:add(Logger(called, 'new bottom'), 'bottom')
		list:draw()
		T.is(#called, 5, "added at bottom")
		T.has(called, {
			'new bottom', 'bottom', 'middle', 'top', 'new top'
		}, "calls all 5 layers")
		empty(called)

		list:add(Logger(called, 'above middle'), 'above', middle)
		list:draw()
		T.is(#called, 6, "added above middle")
		T.has(called, {
			'new bottom', 'bottom', 'middle',
			'above middle', 'top', 'new top'
		}, "calls all 6 layers")
		empty(called)

		list:add(Logger(called, 'below middle'), 'below', middle)
		list:draw()
		T.is(#called, 7, "added below middle")
		T.has(called, {
			'new bottom', 'bottom', 'below middle',
			'middle', 'above middle', 'top', 'new top'
		}, "calls all 7 layers")
		empty(called)

		list:remove(middle)
		list:draw()
		T.is(#called, 6, "removed middle")
		T.has(called, {
			'new bottom', 'bottom', 'below middle',
			'above middle', 'top', 'new top'
		}, "calls all 6 layers")
		empty(called)
	end
}
