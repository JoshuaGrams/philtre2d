-- Simple TAP-compatible testing.

local objectToString = require 'lib.object-to-string'

local coverage = false
local tested, failed = 0, 0

if testCoverage then
	coverage = require(testCoverage.module)
	coverage.init(testCoverage.config)
end

local function note(msg)
	local space = msg and not string.match(msg, '^\t') or false
	print((space and "# " or '#') .. (msg or ''))
end

local function plan(n)
	if n then
		print("1.." .. n)
	else
		print("1.." .. tested)
		if failed > 0 then
			local msg = tostring(failed) .. " of "
			msg = msg .. tostring(tested) .. " tests failed!"
			note(msg)
		end
	end
end

local function bail(msg)
	print("Bail out!")
	error(msg)
end

-- `test` is one of:
-- * function
-- * { string, {tests}, [setup = function], [teardown = function] }
local function check(test, context)
	if type(test) == 'function' then
		test(context)
	elseif type(test) == 'table' then
		note(test[1])
		for i,t in ipairs(test[2]) do
			local context
			if test.setup then context = test.setup() end
			check(t, context)
			if test.teardown then test.teardown(context) end
		end
	end
end

local function ok(ok, msg)
	tested = tested + 1
	if not ok then failed = failed + 1 end
	local status = (ok and 'ok ' or 'not ok ') .. tested
	local space = msg and not string.match(msg, '^\t') or false
	print(status .. (space and ' ' or '') .. (msg or ''))
end

local function is(a, b, msg)
	ok(a == b, msg)
	if a ~= b then
		-- TODO - handle multi-line output from objectToString.
		note("Expected " .. objectToString(b))
		note(" but got " .. objectToString(a))
	end
end

local function has(actual, expected, msg, path)
	path = path or 'obj'
	for k,v in pairs(expected) do
		if type(v) == 'table' and type(actual[k]) == 'table' then
			has(actual[k], v, msg, path .. '.' .. k)
		else
			is(actual[k], v, path .. '.' .. k .. ': ' .. msg)
		end
	end
end

return {
	note = note, plan = plan, bail = bail, check = check,
	ok = ok, is = is, has = has
}
