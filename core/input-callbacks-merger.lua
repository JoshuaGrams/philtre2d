
-- Each side of each axis is separated, so the input name includes its sign.
-- 	Example: "leftx+"

local function rawInput(device, id, val, isRepeat, x, y, dx, dy, isTouch, presses)
	print(device, id, val)
end

-- Using lookup tables is faster than concatenating strings for every input.
local JOY_NAME = {}
for i=1,12 do  JOY_NAME[i] = "joy"..i  end

local AXIS_NAME = {}
for i=1,16 do  AXIS_NAME[i] = { "axis"..i.."+", "axis"..i.."-" }  end

local HAT_NAME = {}
for i=1,6 do
	local hat = "hat"..i
	HAT_NAME[i] = { x1 = hat.."x+", x2 = hat.."x-", y1 = hat.."y+", y2 = hat.."y-" }
end

local PAD_AXIS_NAME = {
	leftx = { "leftx+", "leftx-" },
	lefty = { "lefty+", "lefty-" },
	rightx = { "rightx+", "rightx-" },
	righty = { "righty+", "righty-" },
	triggerleft = { "triggerleft+", "triggerleft-" },
	triggerright = { "triggerright+", "triggerright-" },
}

-- Extra arg order: isRepeat, x, y, dx, dy, isTouch, presses
local callbacks = {
	keypressed = function(key, scancode, isRepeat)
		rawInput("key", key, 1, isRepeat)
		rawInput("scancode", scancode, 1, isRepeat)
	end,
	keyreleased = function(key, scancode)
		rawInput("key", key, 0)
		rawInput("scancode", scancode, 0)
	end,
	textinput = function(text)
		rawInput("text", "text", text)
	end,
	mousepressed = function(x, y, button, isTouch, presses)
		rawInput("mouse", button, 1, nil, x, y, nil, nil, isTouch, presses)
	end,
	mousereleased = function(x, y, button, isTouch, presses)
		rawInput("mouse", button, 0, nil, x, y, nil, nil, isTouch, presses)
	end,
	mousemoved = function(x, y, dx, dy, isTouch)
		rawInput("mouse", "moved", 0, nil, x, y, dx, dy, isTouch)
	end,
	wheelmoved = function(x, y)
		-- Treat mouse wheel like a button that's pressed and immediately released.
		if x ~= 0 then
			local name = "wheelx+"
			local value = 1
			if x < 0 then
				name = "wheelx-"
			end
			rawInput("mouse", name, value, nil, nil, nil, x, 0) -- value, isRepeat, x, y, dx, dy
			rawInput("mouse", name, 0,     nil, nil, nil, x, 0)
		end
		if y ~= 0 then
			local name = "wheely+"
			local value = 1
			if y < 0 then
				name = "wheely-"
			end
			rawInput("mouse", name, value, nil, nil, nil, 0, y)
			rawInput("mouse", name, 0,     nil, nil, nil, 0, y)
		end
	end,
	joystickpressed = function(joystick, button)
		if joystick:isGamepad() then  return  end
		rawInput(JOY_NAME[joystick:getID()], button, 1)
	end,
	joystickreleased = function(joystick, button)
		if joystick:isGamepad() then  return  end
		rawInput(JOY_NAME[joystick:getID()], button, 0)
	end,
	joystickaxis = function(joystick, axisIdx, value) -- Axes are split into two analog inputs, + and -.
		if joystick:isGamepad() then  return  end
		local joyName = JOY_NAME[joystick:getID()]
		if value == 0 then
			rawInput(joyName, AXIS_NAME[axisIdx][1], 0) -- "axis1+"
			rawInput(joyName, AXIS_NAME[axisIdx][2], 0) -- "axis1-"
		elseif value > 0 then
			rawInput(joyName, AXIS_NAME[axisIdx][1], value) -- "axis1+"
		elseif value < 0 then
			rawInput(joyName, AXIS_NAME[axisIdx][2], -value) -- "axis1-" - Remember to make value positive.
		end
	end,
	joystickhat = function(joystick, hat, dir) -- Hats act like two axes, but give weird lettered `dir` inputs. Treat them like four buttons.
		if joystick:isGamepad() then  return  end
		local joyName = JOY_NAME[joystick:getID()]
		-- Name inputs like two axes: hat1x+, hat1x-, hat1y+, hat1y-
		-- Do Y-axis the same as joysticks, with -Y up.
		local hatNames = HAT_NAME[hat]
		if dir == "c" then
			rawInput(joyName, hatNames.x1, 0)
			rawInput(joyName, hatNames.x2, 0)
			rawInput(joyName, hatNames.y1, 0)
			rawInput(joyName, hatNames.y2, 0)
		elseif dir == "u" then
			rawInput(joyName, hatNames.y2, 1)
		elseif dir == "d" then
			rawInput(joyName, hatNames.y1, 1)
		elseif dir == "l" then
			rawInput(joyName, hatNames.x2, 1)
		elseif dir == "r" then
			rawInput(joyName, hatNames.x1, 1)
		elseif dir == "lu" then
			rawInput(joyName, hatNames.x2, 1)
			rawInput(joyName, hatNames.y2, 1)
		elseif dir == "ld" then
			rawInput(joyName, hatNames.x2, 1)
			rawInput(joyName, hatNames.y1, 1)
		elseif dir == "ru" then
			rawInput(joyName, hatNames.x1, 1)
			rawInput(joyName, hatNames.y2, 1)
		elseif dir == "rd" then
			rawInput(joyName, hatNames.x1, 1)
			rawInput(joyName, hatNames.y1, 1)
		end
	end,
	gamepadpressed = function(joystick, button)
		rawInput(JOY_NAME[joystick:getID()], button, 1)
	end,
	gamepadreleased = function(joystick, button)
		rawInput(JOY_NAME[joystick:getID()], button, 0)
	end,
	gamepadaxis = function(joystick, axis, value) -- Axes are split into two analog inputs, + and -.
		local joyName = JOY_NAME[joystick:getID()]
		if value == 0 then
			rawInput(joyName, PAD_AXIS_NAME[axis][1], 0) -- "lefty+"
			rawInput(joyName, PAD_AXIS_NAME[axis][2], 0) -- "lefty-"
		elseif value > 0 then
			rawInput(joyName, PAD_AXIS_NAME[axis][1], value) -- "lefty+"
		elseif value < 0 then
			rawInput(joyName, PAD_AXIS_NAME[axis][2], -value) -- "lefty-" - Remember to make value positive.
		end
	end,
}

local function mergeCallback(name)
	assert(callbacks[name], 'merge-input-callback - Unrecognized callback name: "' .. tostring(name) .. '".')
	local oldFn = love[name]
	local newFn = callbacks[name]
	love[name] = oldFn and function(...)
		oldFn(...)
		newFn(...)
	end  or newFn
end

local function mergeInputCallbacks(outputFn, callbackName, ...)
	rawInput = outputFn or rawInput
	if callbackName then
		local list = {callbackName, ...}
		for _,name in ipairs(list) do
			mergeCallback(name)
		end
	else
		for name,_ in pairs(callbacks) do
			mergeCallback(name)
		end
	end
end

return mergeInputCallbacks
