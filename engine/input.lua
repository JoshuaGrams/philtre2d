
----------------------------------------------------------------
-- Objects which receive logical and raw (physical) inputs.
local O, R = {}, {}

local function enable(obj, raw)
	(raw and R or O)[obj] = obj
end

local function disable(obj)
	O[obj], R[obj] = nil, nil
end

local function disable_all()
	O, R = {}, {}
end


----------------------------------------------------------------
-- Physical inputs.

local P = {}
-- [key][name]
-- [scancode][name]
-- [joystick#][button#]
-- [joystick#][axis#]
-- [joystick#][hat#up/down/left/right]
-- [joystick#][name] - gamepad has named axes/buttons.

-- Returns true if the physical input is already bound.
local function use_physical(logical, device, input)
	if not P[device] then P[device] = {} end
	local dev = P[device]
	if dev[input] then
		table.insert(dev[input].bindings, logical)
		return true
	else
		dev[input] = {
			device = device, input = input,
			value = 0, change = 0,
			bindings = {logical}
		}
		return false
	end
end


----------------------------------------------------------------
-- Logical inputs.

local L = {}

local function logical_input(name)
	if not L[name] then
		L[name] = {
			name = name,
			value = 0, change = 0,
			-- {fn=fn, phy, ...}
			-- fn(value, phy, ...) -> value'
			physical = {}
		}
	end
	return L[name]
end

local function to_physical(name)
	local out
	local i = L[name]
	if i then
		out = {}
		for _,args in ipairs(i.physical) do
			local p = args[1]
			if not p[1] then p = {p} end
			for _,phy in ipairs(p) do
				table.insert(out, {phy.device, phy.input})
			end
		end
	end
	return out
end

-- Set logical input, perform callbacks.
local function update_logical(l)
	-- Combine physical inputs to get new logical value.
	local v = 0
	for _,p in ipairs(l.physical) do
		v = p.fn(v, unpack(p))
	end
	l.value, l.change = v, v - l.value
	-- Call objects that want input.
	for _,o in pairs(O) do
		if not o.paused then
			o:input(l.name, l.value, l.change)
		end
	end
end


----------------------------------------------------------------
-- Handlers for collecting axes and buttons and converting
-- between the two.

local function axis_handler(v, phy)
	local a = phy.value
	local pos, neg = math.max(0, a, v), math.min(0, a, v)
	return pos + neg
end

local function button_axis_handler(v, phy)
	local pos = math.max(v, phy[1].value)
	local neg = math.min(v, -phy[2].value)
	return pos + neg
end

local function button_handler(v, phy)
	return math.max(v, phy.value)
end

local function axis_button_handler(v, phy, dir, lim)
	return math.max(v, (dir*phy.value > lim) and 1 or 0)
end


----------------------------------------------------------------
-- Bind logical axes and buttons to physical axes or buttons.

local function axis(name, device, input)
	local l = logical_input(name)
	local r = use_physical(l, device, input)
	table.insert(l.physical, {fn=axis_handler, P[device][input]})
	return r
end

local function axis_from_buttons(name, dev1, in1, dev2, in2)
	local l = logical_input(name)
	local r1 = use_physical(l, dev1, in1)
	local r2 = use_physical(l, dev2, in2)
	local p = {fn=button_axis_handler, {P[dev1][in1], P[dev2][in2]}}
	table.insert(l.physical, p)
	return r1, r2
end

local function button(name, device, input)
	local l = logical_input(name)
	local r = use_physical(l, device, input)
	table.insert(l.physical, {fn=button_handler, P[device][input]})
	return r
end

local function button_from_axis(name, device, input, lim, dir)
	local l = logical_input(name)
	local r = use_physical(l, device, input)
	lim, dir = lim or 0.5, dir or 1
	local p = {fn=axis_button_handler, P[device][input], dir, lim}
	table.insert(l.physical, p)
	return r
end

local binder = {
	axis = axis, button = button,
	axis_from_buttons = axis_from_buttons,
	button_from_axis = button_from_axis
}

-- Normally, this function adds to the existing bindings. If
-- `replace_old` is true, it will remove all old bindings for
-- these logical inputs, replacing them with the new ones.
-- Note that it *never* affects inputs which aren't mentioned
-- in `bindings`.
local function bind(bindings, replace_old)
	local cleared = {}
	for _,b in ipairs(bindings) do
		local name, kind = b[1], b[2]
		if replace_old and not cleared[name] then
			L[name] = nil
			cleared[name] = true
		end
		binder[kind](name, unpack(b,3))
	end
end

local function unbind(bindings)
	for _,b in ipairs(bindings) do
		L[b[1]] = nil
	end
end

local function unbind_all()  L = {}  end


----------------------------------------------------------------
-- Physical event handlers.

local function to_logical(device, input)
	local out
	local i = P[device][input]
	if i then
		out = {}
		for _,l in ipairs(i.bindings) do
			table.insert(out, l.name)
		end
	end
	return out
end

-- Set physical input.
local function phy(v, device, input)
	-- Notify objects of raw input.
	for _,o in pairs(R) do
		if not o.paused then
			o.input({device, input}, v)
		end
	end
	-- Update logical inputs, if any.
	local i = P[device] and P[device][input]
	if i then
		i.value, i.change = v, v - i.value
		for _,l in ipairs(i.bindings) do
			update_logical(l)
		end
	end
end

local callbacks = {}

function callbacks.keypressed(k, s)
	phy(1, 'key', k)
	phy(1, 'scancode', s)
end

function callbacks.keyreleased(k, s)
	phy(0, 'key', k)
	phy(0, 'scancode', s)
end

function callbacks.mousepressed(x, y, button)
	phy(1, 'mouse', button)
end

function callbacks.mousereleased(x, y, button)
	phy(0, 'mouse', button)
end

local function joy(j) return 'joystick' .. tostring(j:getID()) end
local function jb(j, b) return joy(j), 'button' .. tostring(b) end
local function ja(j, a) return joy(j), 'axis' .. tostring(a) end
local hatButtons = {
	c  = {up=0, down=0, left=0, right=0},
	u  = {up=1, down=0, left=0, right=0},
	lu = {up=1, down=0, left=1, right=0},
	l  = {up=0, down=0, left=1, right=0},
	ld = {up=0, down=1, left=1, right=0},
	d  = {up=0, down=1, left=0, right=0},
	rd = {up=0, down=1, left=0, right=1},
	r  = {up=0, down=0, left=0, right=1},
	ru = {up=1, down=0, left=0, right=1}
}

function callbacks.joystickpressed(j, b) phy(1, jb(j,b)) end
function callbacks.joystickreleased(j, b) phy(0, jb(j,b)) end
function callbacks.joystickaxis(j, a, v) phy(v, ja(j,a)) end
function callbacks.joystickhat(j, h, dir)
	j, h = joy(j), 'hat' .. tostring(h)
	for _,b in ipairs(hatButtons[dir]) do
		local name, value = unpack(b)
		phy(value, j, h..name)
	end
end

function callbacks.gamepadpressed(j, b) phy(1, joy(j), b) end
function callbacks.gamepadreleased(j, b) phy(0, joy(j), b) end
function callbacks.gamepadaxis(j, a, v) phy(v, joy(j), a) end

local function init()
	for name,fn in pairs(callbacks) do
		local old = love[name]
		love[name] = old and function(...)
			old(...); fn(...)
		end or fn
	end
end


----------------------------------------------------------------

return {
	init = init,
	enable = enable, disable = disable,
	disable_all = disable_all,
	bind = bind, unbind = unbind,
	unbind_all = unbind_all,
	to_physical = to_physical, to_logical = to_logical
}
