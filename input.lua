
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
		local v = device == "text" and "" or 0
		dev[input] = {
			device = device, input = input,
			value = v, change = v,
			bindings = {logical}
		}
		return false
	end
end


----------------------------------------------------------------
-- Logical inputs.

local L = {}

local function register_logical(name, device, input)
	-- Save device and input here so we can remove the physical binding later.
	if not L[name] then
		L[name] = {
			name = name,
			value = 0, change = 0,
			device = device,
			input = input,
			-- {fn=fn, phy, ...}
			-- fn(value, phy, ...) -> value'

			physical = {}
		}
	end
	return L[name]
end

local function get_logical(name)
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
	local val = 0
	for _,p in ipairs(l.physical) do
		val = p.fn(val, unpack(p))
	end
	if l.device ~= 'text' then
		l.change = val - l.value
	end
	l.value = val
	-- Call objects that want input.
	for _,o in pairs(O) do
		o:call('input', l.name, l.value, l.change)
	end
end


----------------------------------------------------------------
-- Handlers for collecting axes and buttons and converting
-- between the two.

local function axis_handler(val, phy)
	local a = phy.value
	local pos, neg = math.max(0, a, val), math.min(0, a, val)
	return pos + neg
end

local function button_axis_handler(val, phy)
	local pos = math.max(val, phy[1].value)
	local neg = math.min(val, -phy[2].value)
	return pos + neg
end

local function button_handler(val, phy)
	return math.max(val, phy.value)
end

local function axis_button_handler(val, phy, dir, lim)
	return math.max(val, (dir*phy.value > lim) and 1 or 0)
end

local function text_handler(val, phy)
	return phy.value
end


----------------------------------------------------------------
-- Bind logical axes and buttons to physical axes or buttons.

local function axis(name, device, input)
	local l = register_logical(name, device, input)
	local r = use_physical(l, device, input)
	table.insert(l.physical, {fn=axis_handler, P[device][input]})
	return r
end

local function axis_from_buttons(name, dev1, in1, dev2, in2)
	local l = register_logical(name, device, input)
	local r1 = use_physical(l, dev1, in1)
	local r2 = use_physical(l, dev2, in2)
	local p = {fn=button_axis_handler, {P[dev1][in1], P[dev2][in2]}}
	table.insert(l.physical, p)
	return r1, r2
end

local function button(name, device, input)
	local l = register_logical(name, device, input)
	local r = use_physical(l, device, input)
	table.insert(l.physical, {fn=button_handler, P[device][input]})
	return r
end

local function button_from_axis(name, device, input, lim, dir)
	local l = register_logical(name, device, input)
	local r = use_physical(l, device, input)
	lim, dir = lim or 0.5, dir or 1
	local p = {fn=axis_button_handler, P[device][input], dir, lim}
	table.insert(l.physical, p)
	return r
end

local function text(name, device, input)
	local l = register_logical(name, device, input)
	local r = use_physical(l, device, input)
	table.insert(l.physical, {fn=text_handler, P[device][input]})
	return r
end

local binder = {
	axis = axis, button = button,
	axis_from_buttons = axis_from_buttons,
	button_from_axis = button_from_axis,
	text = text
}

-- Private. Unbinds one logical action name.
local function _unbind(name)
	assert(type(name) == 'string', 'Input._unbind - Invalid name "' .. name .. '". Action names must be strings.')
	local logic_data = L[name]
	if logic_data then
		-- Remove from logical inputs list.
		L[name] = nil

		-- Remove from physical input.
		local phy_data = P[logic_data.device][logic_data.input]
		for i=#phy_data.bindings, 1, -1 do
			local l_bind = phy_data.bindings[i]
			if l_bind.name == name then
				phy_data.bindings[i] = nil
			end
		end
		-- If that phys. input has no other logical actions on it, clear it.
		if #phy_data.bindings == 0 then
			P[logic_data.device][logic_data.input] = nil
		end
	else
		print('WARNING: Input._unbind - Tried to unbind nonexistent action name: "' .. name .. '".')
	end
end

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
			_unbind(name)
			cleared[name] = true
		end
		if binder[kind] then -- Call binder func for this input type.
			if L[name] then
				error('Input.bind - replace_old=false and action name "' .. name .. '" is already bound.')
			end
			binder[kind](name, unpack(b,3))
		else -- Handle invalid kind/type error.
			local tList = ""
			for k, v in pairs(binder) do
				tList = string.format("%s %s %s %s", tList, '\t', k, '\n')
			end
			local errMsg = string.format(
				"%s%s%s%s",
				'Input.bind - Invalid type "', kind,
				'". Should be one of the following:\n', tList
			)
			error(errMsg)
		end
	end
end

local function unbind(bindings)
	if type(bindings) == 'string' then
		-- A single logical action name.
		_unbind(bindings)
	elseif type(bindings) == 'table' and type(bindings[1]) == 'string' then
		-- A table of logical action names.
		for i,name in ipairs(bindings) do _unbind(name) end
	elseif type(bindings) == 'table' and type(bindings[1]) == 'table' then
		-- A table of tables with action names as their first element.
		for _,b in ipairs(bindings) do _unbind(b[1]) end
	else
		error('Input.unbind - Invalid argument: ' .. tostring(bindings) .. '. It should be a string, a table of strings, or a table of tables with strings as their first element.')
	end
end

local function unbind_all()
	L = {}
	P = {}
end


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

-- This is always called for every input that the device receives.
-- Binder functions register logical AND physical input.
local function phy(val, device, input)
	-- Send all raw physical input to any objects registered for it.
	for _,o in pairs(R) do
		if not o.paused then
			o:call('input', device, input, val)
		end
	end
	-- If any logical inputs are registered to this physical input, update them.
	local i = P[device] and P[device][input]
	if i then
		if device ~= 'text' then
			i.change = val - i.value
		end
		i.value = val
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

function callbacks.wheelmoved(x, y)
	if y ~= 0 then  phy(y, 'mouse', 'wheel y')  end
	if x ~= 0 then  phy(x, 'mouse', 'wheel x')  end
end

function callbacks.textinput(t)
	phy(t, 'text', 'text')
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
	to_physical = to_physical, to_logical = to_logical,
	get = get_logical
}
