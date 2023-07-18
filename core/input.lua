
local Input = {}

local folder = (...):gsub("input$", "")
local mergeInputCallbacks = require(folder .. "input-callbacks-merger")
local InputStack = require(folder .. "input-stack")

local stack = InputStack()
local rawStack = InputStack("rawInput")
Input.stack = stack
Input.rawStack = rawStack

local deviceAbbreviation = { [""] = "scancode", k = "key", m = "mouse", j = "joy", t = "text" }

local DEVICES = { "key", "scancode", "mouse", "text"--[[, "joy1", "joy2", etc.]] }
local MAX_JOYSTICK_COUNT = 12
for i=1,MAX_JOYSTICK_COUNT do  table.insert(DEVICES, "joy"..i)  end

local actionsForInput = {} -- actionsForInput[device][id] = { {name=, flipAxis=}, ... }
local inputsForAction = {} -- inputsForAction[actionName] = { {device=, id=}, ... }
local actions = {}         -- actions[actionName] = Action
local rawValues = {}       -- rawValues[device][id] = value

for _,device in ipairs(DEVICES) do
	actionsForInput[device] = {}
	rawValues[device] = {}
end

local IS_VALID_ACTION_TYPE = { button = true, axis = true, cursor = true, text = true}
local VALID_ACTIONS_STR = "'button', 'axis', 'cursor', or 'text'"

--------------------  Action Object  --------------------
local function Action(actionType)
	assert(
		IS_VALID_ACTION_TYPE[actionType],
		"Input.newAction - Invalid `actionType` '"..tostring(actionType)..
		"'. Must be one of the following: "..VALID_ACTIONS_STR.."."
	)
	return {
		type = actionType,
		value = 0,
		total = 0
	}
end

--------------------  Utilities  --------------------
local floor = math.floor

local function round(x)  return floor(x + 0.5)  end

local function clamp(x, min, max)
	return x < min and min or (x > max and max) or x
end

--------------------  Initialization / Setup  --------------------
function Input.init()
	mergeInputCallbacks(Input.rawInput)
end

--------------------  Subscribe & Unsubscribe From Input  --------------------
function Input.enable(object, index)
	stack:add(object, index)
end

function Input.disable(object)
	stack:remove(object)
end

function Input.enableRaw(object, index)
	rawStack:add(object, index)
end

function Input.disableRaw(object)
	rawStack:remove(object)
end

local SKIP_ACTIONS = -1

--------------------  Handling Input  --------------------
function Input.rawInput(device, id, rawValue, ...)
	local oldRawValue = rawValues[device][id] or 0
	rawValues[device][id] = rawValue
	local rawChange
	if id ~= "text" then
		rawChange = rawValue - oldRawValue
	end

	local r = rawStack:call(device, id, rawValue, rawChange, ...)
	if r == SKIP_ACTIONS then  return  end

	local actionBindings = actionsForInput[device][id]
	if actionBindings then
		for _,binding in pairs(actionBindings) do
			local actionName = binding.name
			local action = actions[actionName]

			if action.type == "axis" then
				local axisRawChange = rawChange
				if binding.flipAxis then  axisRawChange = -axisRawChange  end
				local oldValue = action.value
				action.total = action.total + axisRawChange
				action.value = clamp(action.total, -1, 1)
				local change = action.value - oldValue
				stack:call(actionName, action.value, change, axisRawChange, ...)

			elseif action.type == "button" then
				local btnRawChange = round(rawValue) - round(oldRawValue)
				local oldValue = action.value
				action.total = action.total + btnRawChange
				action.value = action.total >= 1 and 1 or 0
				local change = action.value - oldValue
				stack:call(actionName, action.value, change, btnRawChange, ...)

			elseif action.type == "cursor" then
				stack:call(actionName, 0, 0, 0, ...)

			elseif action.type == "text" then
				action.value = rawValue
				stack:call(actionName, rawValue, 0, 0, ...)

			end
		end
	end
end

--------------------  Polling & Checking Input Status  --------------------
function Input.get(actionName)
	local action = actions[actionName]
	assert(action, "Input.get - No action found by the action-name '"..tostring(actionName).."'.")
	return action.value, action.total
end

function Input.getRaw(device, id)
	return rawValues[device] and rawValues[device][id]
end

function Input.isPressed(actionName)
	local action = actions[actionName]
	assert(action, "Input.isPressed - No action found by the action-name '"..tostring(actionName).."'.")
	if action.type == "button" then
		return action.value >= 0.5
	end
end

function Input.getInputs(actionName)
	return inputsForAction[actionName]
end

function Input.getActions(device, id)
	return actionsForInput[device][id]
end

function Input.getActionType(actionName)
	local action = actions[actionName]
	if action then  return action.type  end
end

--------------------  Binding  --------------------
local function parseInputString(inputStr)
	inputStr = string.lower(inputStr)

	-- If device is specified, parse and remove it.
	local i1,i2,device,joyNum = string.find(inputStr, "^(%a+)(%d?):.")
	local id
	if device then
		id = string.sub(inputStr, i2)
	else
		id = inputStr
	end

	device = deviceAbbreviation[device] or device or "scancode"
	if joyNum then  device = device .. joyNum  end
	if device == "mouse" then  id = tonumber(id) or id  end -- Love sends the mouse btn number (not the string) to mousepressed/released.

	assert(device and id, "Input.parseInputString - couldn't parse input-string '"..tostring(inputStr).."'.")
	return device, id
end

local function reSumActionValue(actionName)
	local action = actions[actionName]
	if not action then  return  end
	local actionType = action.type
	-- "text" action value is always typed text, you only change the action name.
	-- "cursor" action doesn't have a value.
	if actionType == "text" or actionType == "cursor" then  return  end

	local inputs = Input.getInputs(actionName)
	local total = 0
	if inputs then
		for i,v in ipairs(inputs) do -- {device=, id=, flipAxis=}
			local rawValue = rawValues[v.device][v.id] or 0
			if actionType == "button" then  rawValue = round(rawValue)  end
			if v.flipAxis then  rawValue = -rawValue  end
			total = total + rawValue
		end
	end
	action.total = total
	if actionType == "button" then
		action.value = action.total >= 1 and 1 or 0
	elseif actionType == "axis" then
		action.value = clamp(action.total, -1, 1)
	end
end

local function addBinding(device, id, actionName, flipAxis)
	actionsForInput[device][id] = actionsForInput[device][id] or {}
	table.insert(actionsForInput[device][id], { name = actionName, flipAxis = flipAxis })

	inputsForAction[actionName] = inputsForAction[actionName] or {}
	table.insert(inputsForAction[actionName], { device = device, id = id, flipAxis = flipAxis })
	reSumActionValue(actionName)
end

local function ensureActionExists(actionName, actionType)
	local action = actions[actionName]
	if action then
		assert(action.type == actionType, "Input.bind - The action '"..actionName.."' already exists with action-type: '"..action.type.."'. Can't bind the same action name to action-type: '"..actionType.."'.")
	else
		actions[actionName] = Action(actionType)
	end
end

-- Can be called with one, two, three, or four arguments:
function Input.bind(actionType, b, c, d)
	-- Input.bind(table) -- list of bindings.
	if type(actionType) == "table" then
		local bindingList = actionType
		for _,B in ipairs(bindingList) do
			Input.bind(B[1], B[2], B[3], B[4]) -- unpack might fail if nil is included for one half of an axis.
		end

	-- Input.bind(actionType, inputStr, actionName)
	elseif actionType == "button" then
		local inputStr, actionName = b, c
		ensureActionExists(actionName, actionType)
		local device, id = parseInputString(inputStr)
		addBinding(device, id, actionName)

	-- Input.bind("axis", inputStrNeg, inputStrPos, actionName)
	elseif actionType == "axis" then
		local inputStrNeg, inputStrPos, actionName = b, c, d
		ensureActionExists(actionName, actionType)
		if inputStrNeg then
			local device, id = parseInputString(inputStrNeg)
			addBinding(device, id, actionName, true)
		end
		if inputStrPos then
			local device, id = parseInputString(inputStrPos)
			addBinding(device, id, actionName, false)
		end

	-- Input.bind("text", actionName)
	elseif actionType == "text" then
		local actionName = b
		ensureActionExists(actionName, actionType)
		addBinding("text", "text", actionName)

	-- Input.bind("cursor", actionName)
	elseif actionType == "cursor" then
		local actionName = b
		ensureActionExists(actionName, actionType)
		addBinding("mouse", "moved", actionName)
	end
end

--------------------  Unbinding  --------------------
local function reverse_ipairs_iter(a, i) -- Make custom reverse iterator instead of doing `for i=#list,1,-1` everywhere.
	i = i - 1
	local v = a[i]
	if v then  return i, v  end
end

local function revpairs(t)  return reverse_ipairs_iter, t, #t+1  end

local function findAndRemoveAction(actionBindingList, actionName)
	for i,binding in revpairs(actionBindingList) do
		if binding.name == actionName then  return table.remove(actionBindingList, i)  end
	end
end

local function findAndRemoveInput(inputList, device, id)
	for i,input in revpairs(inputList) do
		if input.device == device and input.id == id then
			return table.remove(inputList, i)
		end
	end
end

-- Unbinds all raw inputs from this action.
function Input.unbindAction(actionName)
	actions[actionName] = nil
	for _,input in revpairs(inputsForAction[actionName]) do
		findAndRemoveAction(actionsForInput[input.device][input.id], actionName)
	end
	inputsForAction[actionName] = nil
	-- No action left, don't need to re-sum.
end

-- Unbinds this raw input from all actions.
function Input.unbindInput(device, id)
	for _,actionBinding in revpairs(actionsForInput[device][id]) do
		local actionName = actionBinding.name
		findAndRemoveInput(inputsForAction[actionName], device, id)
		if #inputsForAction[actionName] == 0 then  actions[actionName] = nil  end
		reSumActionValue(actionName)
	end
	actionsForInput[device][id] = nil
end

-- Unbinds only this raw input from this action.
function Input.unbindFromAction(device, id, actionName)
	findAndRemoveAction(actionsForInput[device][id], actionName)
	findAndRemoveInput(inputsForAction[actionName], device, id)
	if #inputsForAction[actionName] == 0 then  actions[actionName] = nil  end
	reSumActionValue(actionName)
end

return Input
