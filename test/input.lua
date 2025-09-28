local base = (...):gsub('[^%.]+.[^%.]+$', '')
local T = require 'lib.simple-test'

local Input = require(base .. 'core.input')

local function _inputMethod(self, action, value, change, rawChange, ...)
	-- print("", action, value, change, rawChange)
	self.count = self.count + 1
	self.last = { action = action, value = value, change = change }
end

local function newObj(name)
	local obj = {}
	obj.name = name
	obj.input = _inputMethod
	obj.count = 0
	obj.last = {}
	return obj
end

local function newJoystick(index, isGamepad)
	local j = {
		index = index,
		isGamepad = isGamepad,
	}
	j.isGamepad = function(self)  return self.isGamepad  end
	j.getID = function(self)  return self.index  end
	return j
end

return {
	"Input",
	function()
		Input.init()
		Input.bind("button", "n", "test")
		local obj = newObj()
		Input.enable(obj)
		love.keypressed("b", "n", false)
		T.ok(obj.count == 1 and obj.last.action == "test", "Button scancode action works.")
		love.keyreleased("b", "n")
		obj.count = 0
		Input.bind("button", "key:b", "test")
		love.keypressed("b", "n", false)
		T.ok(obj.count == 2 and obj.last.action == "test", "Key & scancode bound to button action work.")

		T.ok(Input.isPressed("test"), "Input.isPressed - is true with two inputs held.")

		local val, total = Input.get("test")
		T.ok(val == 1 and total == 2, "Input.get works, value and total are correct for multiple held inputs.")

		love.keyreleased("b", "n")
		T.ok(obj.count == 4 and obj.last.action == "test", "Releasing key & scancode works.")

		T.ok(not Input.isPressed("test"), "Input.isPressed - is false after releasing both inputs.")

		local boundInputs = Input.getInputs("test")
		T.ok(type(boundInputs) == "table" and #boundInputs == 2, "Input.getInputs correctly gives list with two elements.")
		local input1, input2 = boundInputs[1], boundInputs[1]
		T.ok(input1.device and input1.id and input2.device and input2.id, "   getInput results both have 'device' and 'id' keys.")

		Input.unbindInput("scancode", "n")
		obj.count, obj.last = 0, nil
		love.keypressed("b", "n", false)
		T.has(obj, { count=1, last={action = "test"} }, "Input.unbindInput works - only get one press event for that action now.")
		obj.count, obj.last = 0, nil
		love.keyreleased("b", "n")
		T.has(obj, { count=1, last={ action="test" } }, "Input.unbindInput works - only get one release event for that action now.")

		Input.bind("button", "f", "test")
		Input.bind("button", "w", "test")
		local boundActions = Input.getActions("scancode", "w")
		T.has(boundActions, { {name="test"} }, "Input.getActions returns correct result.")

		Input.unbindFromAction("scancode", "w", "test")
		obj.count = 0
		love.keypressed("w", "w", false)
		love.keyreleased("w", "w")
		T.is(obj.count, 0, "Input.unbindFromAction works to remove that input.")

		obj.count = 0
		love.keypressed("b", "b", true)
		love.keypressed("f", "f", true)
		T.is(obj.count, 2, "Other two inputs are still bound after Input.unbindFromAction.")

		Input.unbindAction("test")
		obj.count = 0
		love.keyreleased("b", "b")
		love.keyreleased("f", "f")
		T.is(obj.count, 0, "Input.unbindAction works to remove multiple inputs.")

		local gamepad1 = newJoystick(1, true)

		Input.bind("axis", "joy1:leftx-", nil, "move x")
		obj.count, obj.last = 0, nil
		love.gamepadaxis(gamepad1, "leftx", -0.4)
		T.has(obj, { count=1, last={ action="move x" } }, "Axis action with simulated joystick input works.")
		T.is(Input.get("move x"), -0.4, "Input.get for axis works, sign is correct.")

		love.gamepadaxis(gamepad1, "leftx", 0)
		Input.unbindInput("joy1", "leftx-")
		Input.bind("axis", nil, "joy1:leftx-", "move x")
		love.gamepadaxis(gamepad1, "leftx", -0.4)
		T.is(Input.get("move x"), 0.4, "Flipped axis binding works correctly, sign is correct.")

		Input.bind("axis", "joy1:leftx+", nil, "move x")
		love.gamepadaxis(gamepad1, "leftx", 0.0)
		love.gamepadaxis(gamepad1, "leftx", 0.6)
		T.is(Input.get("move x"), -0.6, "Bound other side of flipped axis and it works too, sign is correct.")
		love.gamepadaxis(gamepad1, "leftx", 0.0)

		Input.bind({
			{ "text", "text input" },
			{ "cursor", "mouse moved" }
		})
		T.ok(true, "Input.bind with table works.")

		obj.count, obj.last = 0, nil
		love.textinput("#")
		T.has(obj, { count=1, last={ action="text input" } }, "'text' action binding works")
		T.is(Input.get("text input"), "#", "Input.get for 'text' action returns correct character.")

		obj.count, obj.last = 0, nil
		love.mousemoved(100, 100, 1, 3)
		T.has(obj, { count=1, last={ action="mouse moved" } }, "'cursor' action binding works")

		local script = { input = function(self)  self.scriptGotInput = true  end }
		obj.scripts = { script }
		love.textinput("a")
		T.ok(obj.scriptGotInput, "Script on object got input.")

		obj.count, obj.last, obj.scriptGotInput = 0, false, false
		Input.disable(obj)
		love.mousemoved(101, 100, 1, 0)
		T.has(obj, { count=0, last=false, scriptGotInput=false }, "Input.disable works.")

		Input.unbindAction("move x")
		Input.unbindAction("text input")
		Input.unbindAction("mouse moved")

		-- Ensure that trying to unbind a nonexistent action doesn't error/crash.
		local isSuccess, errMsg = pcall(Input.unbindAction, "doesntExist")
		T.ok(isSuccess, "unbindAction() works without errors on nonexistent action.")
		if not isSuccess then  print("ERROR: "..errMsg)  end
		local isSuccess, errMsg = pcall(Input.unbindFromAction, "scancode", "w", "doesntExist")
		T.ok(isSuccess, "unbindFromAction() works without errors on nonexistent action.")
		if not isSuccess then  print("ERROR: "..errMsg)  end
	end,
	function() -- Test unbinding only one half of an axis.
		-- Input.init() -- WARNING: Can't call this twice.
		Input.bind("axis", "w", "s", "myaxis")
		local obj = newObj()
		Input.enable(obj)
		love.keypressed("w", "w", false)
		love.keypressed("s", "s", false)
		love.keyreleased("w", "w", false)
		love.keyreleased("s", "s", false)
		T.ok(obj.count == 4, "Press and release for both directions of an axis binding seems okay.")
		T.is(obj.last.value, 0, "Axis value is back to zero after pressing and releasing both bindings.")
		obj.count = 0
		Input.unbindFromAction("scancode", "s", "myaxis")
		love.keypressed("w", "w", false)
		love.keypressed("s", "s", false)
		T.ok(obj.count == 1, "Pressing both old keys after unbinding correctly results in only one input being processed.")
		T.is(obj.last.value, -1, "Axis value is correct after pressing both old keys after unbinding half of an axis.")
		-- Clean up:
		Input.disable(obj)
		Input.unbindAction("myaxis")
		love.keyreleased("w", "w", false)
		love.keyreleased("s", "s", false)
	end,
	function() -- Test axis binding where both sides are bound to the same input.
		Input.bind("axis", "c", "c", "doubleAxis")
		local obj = newObj()
		Input.enable(obj)
		love.keypressed("c", "c", false)
		T.is(obj.count, 2, "Binding the same key to both sides of an axis makes two events when pressed.")
		T.is(obj.last.value, 0, "Binding the same key to both sides of an axis results in a value of 0 when pressed.")
		obj.count = 0
		love.keyreleased("c", "c", false)
		T.is(obj.count, 2, "Binding the same key to both sides of an axis makes two events when released.")
		T.is(obj.last.value, 0, "Binding the same key to both sides of an axis results in a value of 0 when released.")
		obj.count = 0
		-- Test that unbinding removes it from both sides.
		Input.unbindFromAction("scancode", "c", "doubleAxis")
		love.keypressed("c", "c", false)
		T.is(obj.count, 0, "Unbinding that key removes it from both sides of the axis, no events after it's pressed again.")
		T.is(obj.last.value, 0, "Unbinding that key removes it from both sides of the axis, value still 0 after it's pressed again.")
		Input.unbindAction("doubleAxis")
	end,
}
