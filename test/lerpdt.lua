local base = (...):gsub('[^%.]+.[^%.]+$', '')
local T = require(base .. 'lib.simple-test')

require(base .. 'lib.math-patch')
local vec2 = require(base .. 'lib.vec2xy')

return {
	"Math Patch: lerpdt()",
	function()
		local lerpdt = math.lerpdt
		local from = 10
		local to = 0
		local rate = 0
		T.is(lerpdt(from, to, rate, 1),    from, "Rate 0 gives back original value")
		T.is(lerpdt(from, to, rate, -0.1), from, "Rate 0 gives back original value")
		T.is(lerpdt(from, to, rate, 0.1),  from, "Rate 0 gives back original value")
		T.is(lerpdt(from, to, rate, 1/60), from, "Rate 0 gives back original value")
		T.is(lerpdt(from, to, rate, 1.1),  from, "Rate 0 gives back original value")

		rate = 1
		T.is(lerpdt(from, to, rate, 1),    to, "Rate 1 gives back target value")
		-- NOTE: Can't do negative dt with rate 1.
		T.is(lerpdt(from, to, rate, 0.1),  to, "Rate 1 gives back target value")
		T.is(lerpdt(from, to, rate, 1/60), to, "Rate 1 gives back target value")
		T.is(lerpdt(from, to, rate, 1.1),  to, "Rate 1 gives back target value")

		from, to, rate = 10, 0, 0.25
		local result = lerpdt(from, to, rate, 1)

		from = lerpdt(from, to, rate, 0.75)
		from = lerpdt(from, to, rate, 0.01)
		from = lerpdt(from, to, rate, 0.21)
		from = lerpdt(from, to, rate, 0.01)
		from = lerpdt(from, to, rate, 0.01)
		from = lerpdt(from, to, rate, 0.01)
		T.isNearly(from, result, "Repeated lerp with times summing to 1 matches single lerp with dt=1")

		from, to, rate = 10, -10, 0.25
		T.isNearly(lerpdt(from, to, rate, 1), 5, "Lerp from positive to negative works.")
		from, to, rate = 10, -10, 0.75
		T.isNearly(lerpdt(from, to, rate, 1), -5, "Lerp from positive to negative works.")

		from, to, rate = -10, 30, 0.25
		T.isNearly(lerpdt(from, to, rate, 1), 0, "Lerp from negative to positive works.")
		from, to, rate = -10, 30, 0.75
		T.isNearly(lerpdt(from, to, rate, 1), 20, "Lerp from negative to positive works.")

		from, to, rate = -10, -30, 0.25
		T.isNearly(lerpdt(from, to, rate, 1), -15, "Lerp from negative to negative works.")
		from, to, rate = -10, -30, 0.75
		T.isNearly(lerpdt(from, to, rate, 1), -25, "Lerp from negative to negative works.")

		from, to, rate = -10, 10, 0.25
		local result = lerpdt(from, to, rate, 1)

		from = lerpdt(from, to, rate, 0.75)
		from = lerpdt(from, to, rate, 0.01)
		from = lerpdt(from, to, rate, 0.21)
		from = lerpdt(from, to, rate, 0.01)
		from = lerpdt(from, to, rate, 0.01)
		from = lerpdt(from, to, rate, 0.01)
		T.isNearly(from, result, "Repeated lerp with time increments from negative to positive matches.")

		from, to, rate = 10, -30, 0.25
		local result = lerpdt(from, to, rate, 1)

		from = lerpdt(from, to, rate, 0.75)
		from = lerpdt(from, to, rate, 0.01)
		from = lerpdt(from, to, rate, 0.21)
		from = lerpdt(from, to, rate, 0.01)
		from = lerpdt(from, to, rate, 0.01)
		from = lerpdt(from, to, rate, 0.01)
		T.isNearly(from, result, "Repeated lerp with time increments from positive to negative matches.")
	end,
	"Vec2 X/Y: lerpdt()",
	function()
		local lerpdt = vec2.lerpdt
		local fromX, fromY = 10, 10
		local toX, toY = 0, 0
		local rate = 0
		T.has({lerpdt(fromX, fromY, toX, toY, rate, 1)},    {fromX, fromY}, "Rate 0 gives back original values")
		T.has({lerpdt(fromX, fromY, toX, toY, rate, -0.1)}, {fromX, fromY}, "Rate 0 gives back original values")
		T.has({lerpdt(fromX, fromY, toX, toY, rate, 0.1)},  {fromX, fromY}, "Rate 0 gives back original values")
		T.has({lerpdt(fromX, fromY, toX, toY, rate, 1/60)}, {fromX, fromY}, "Rate 0 gives back original values")
		T.has({lerpdt(fromX, fromY, toX, toY, rate, 1.1)},  {fromX, fromY}, "Rate 0 gives back original values")

		rate = 1
		T.has({lerpdt(fromX, fromY, toX, toY, rate, 1)},    {toX, toY}, "Rate 1 gives back target values")
		-- NOTE: Can't do negative dt with rate 1.
		T.has({lerpdt(fromX, fromY, toX, toY, rate, 0.1)},  {toX, toY}, "Rate 1 gives back target values")
		T.has({lerpdt(fromX, fromY, toX, toY, rate, 1/60)}, {toX, toY}, "Rate 1 gives back target values")
		T.has({lerpdt(fromX, fromY, toX, toY, rate, 1.1)},  {toX, toY}, "Rate 1 gives back target values")

		fromX, fromY, toX, toY, rate = 10, 10, 0, 0, 0.25
		local resultX, resultY = lerpdt(fromX, fromY, toX, toY, rate, 1)

		fromX, fromY = lerpdt(fromX, fromY, toX, toY, rate, 0.75)
		fromX, fromY = lerpdt(fromX, fromY, toX, toY, rate, 0.01)
		fromX, fromY = lerpdt(fromX, fromY, toX, toY, rate, 0.21)
		fromX, fromY = lerpdt(fromX, fromY, toX, toY, rate, 0.01)
		fromX, fromY = lerpdt(fromX, fromY, toX, toY, rate, 0.01)
		fromX, fromY = lerpdt(fromX, fromY, toX, toY, rate, 0.01)
		T.isNearly(fromX, resultX, "Repeated lerp with times summing toX, toY 1 matches single lerp with dt=1 (X)")
		T.isNearly(fromY, resultY, "Repeated lerp with times summing toX, toY 1 matches single lerp with dt=1 (Y)")

		fromX, fromY, toX, toY, rate = 10, 10, -10, -10, 0.25
		T.has({lerpdt(fromX, fromY, toX, toY, rate, 1)}, {5, 5}, "Lerp fromX, fromY positive toX, toY negative works.")
		fromX, fromY, toX, toY, rate = 10, 10, -10, -10, 0.75
		T.has({lerpdt(fromX, fromY, toX, toY, rate, 1)}, {-5, -5}, "Lerp fromX, fromY positive toX, toY negative works.")

		fromX, fromY, toX, toY, rate = -10, -10, 30, 30, 0.25
		T.has({lerpdt(fromX, fromY, toX, toY, rate, 1)}, {0, 0}, "Lerp fromX, fromY negative toX, toY positive works.")
		fromX, fromY, toX, toY, rate = -10, -10, 30, 30, 0.75
		T.has({lerpdt(fromX, fromY, toX, toY, rate, 1)}, {20, 20}, "Lerp fromX, fromY negative toX, toY positive works.")

		fromX, fromY, toX, toY, rate = -10, -10, -30, -30, 0.25
		T.has({lerpdt(fromX, fromY, toX, toY, rate, 1)}, {-15, -15}, "Lerp fromX, fromY negative toX, toY negative works.")
		fromX, fromY, toX, toY, rate = -10, -10, -30, -30, 0.75
		T.has({lerpdt(fromX, fromY, toX, toY, rate, 1)}, {-25, -25}, "Lerp fromX, fromY negative toX, toY negative works.")

		fromX, fromY, toX, toY, rate = -10, -10, 10, 10, 0.25
		local resultX, resultY = lerpdt(fromX, fromY, toX, toY, rate, 1)

		fromX, fromY = lerpdt(fromX, fromY, toX, toY, rate, 0.75)
		fromX, fromY = lerpdt(fromX, fromY, toX, toY, rate, 0.01)
		fromX, fromY = lerpdt(fromX, fromY, toX, toY, rate, 0.21)
		fromX, fromY = lerpdt(fromX, fromY, toX, toY, rate, 0.01)
		fromX, fromY = lerpdt(fromX, fromY, toX, toY, rate, 0.01)
		fromX, fromY = lerpdt(fromX, fromY, toX, toY, rate, 0.01)
		T.isNearly(fromX, resultX, "Repeated lerp with time increments fromX, fromY negative toX, toY positive matches. (X)")
		T.isNearly(fromY, resultY, "Repeated lerp with time increments fromX, fromY negative toX, toY positive matcheY. (Y)")

		fromX, fromY, toX, toY, rate = 10, 10, -30, -30, 0.25
		local resultX, resultY = lerpdt(fromX, fromY, toX, toY, rate, 1)

		fromX, fromY = lerpdt(fromX, fromY, toX, toY, rate, 0.75)
		fromX, fromY = lerpdt(fromX, fromY, toX, toY, rate, 0.01)
		fromX, fromY = lerpdt(fromX, fromY, toX, toY, rate, 0.21)
		fromX, fromY = lerpdt(fromX, fromY, toX, toY, rate, 0.01)
		fromX, fromY = lerpdt(fromX, fromY, toX, toY, rate, 0.01)
		fromX, fromY = lerpdt(fromX, fromY, toX, toY, rate, 0.01)
		T.isNearly(fromX, resultX, "Repeated lerp with time increments from positive to negative matches. (X)")
		T.isNearly(fromY, resultY, "Repeated lerp with time increments from positive to negative matches. (Y)")
	end,
}
