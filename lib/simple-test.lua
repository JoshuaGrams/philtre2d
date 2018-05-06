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

local function check(test, context)
	if type(test) == 'function' then
		test(context)
	elseif type(test) == 'string' then
		note(test)
	elseif type(test) == 'table' then
		for i,t in ipairs(test) do
			local context
			if test.setup then context = test.setup() end
			check(t, context)
			if test.teardown then test.teardown(context) end
		end
	end
end

-- Must be called exactly once, either at the beginning
-- or at the end.
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

local function ok(ok, msg)
	tested = tested + 1
	if not ok then failed = failed + 1 end
	local status = (ok and 'ok ' or 'not ok ') .. tested
	local space = msg and not string.match(msg, '^\t') or false
	print(status .. (space and ' ' or '') .. (msg or ''))
	if not ok then
		print(string.gsub('# ' .. debug.traceback(), '\n', '\n# '))
	end
	return ok
end

local function is(a, b, msg)
	local yes = (a == b)
	ok(yes, msg)
	if not yes then
		-- TODO - handle multi-line output from objectToString.
		note("Expected " .. objectToString(b, '#'))
		note(" but got " .. objectToString(a, '#'))
	end
	return yes
end

local function has(actual, expected, msg, path)
	path = path or 'obj'
	local yes = true
	for k,v in pairs(expected) do
		if type(v) == 'table' and type(actual[k]) == 'table' then
			yes = yes and has(actual[k], v, msg, path .. '.' .. k)
		else
			yes = yes and is(actual[k], v, path .. '.' .. k .. ': ' .. msg)
		end
	end
	return yes
end

local function bail(msg)
	print("Bail out!")
	error(msg)
end

return {
	check = check, plan = plan,
	ok = ok, is = is, has = has,
	note = note, bail = bail
}
