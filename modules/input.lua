
local basePath = (...):gsub('[^%.]+$', '')
local inputStack = require(basePath .. "input-stack")

local min, max, floor = math.min, math.max, math.floor
local function sign(x)
	return x > 0 and 1 or (x < 0 and -1 or x)
end

local virtualKeyPressCount = { ctrl = 0, alt = 0, shift = 0, enter = 0}
local virtualKeys = {
	lctrl = "ctrl", rctrl = "ctrl",
	lalt = "alt", ralt = "alt",
	lshift = "shift", rshift = "shift",
	["return"] = "enter", kpenter = "enter"
}

local rawValues = { key = {}, scancode = {}, text = {}, mouse = {} } -- [device][id] = value
rawValues.mouse.moved = { x = 0, y = 0, dx = 0, dy = 0 }

local MAX_JOYSTICK_COUNT = 12
for i=1,MAX_JOYSTICK_COUNT do  rawValues["joy"..i] = {}  end

local group = {}
group.__index = group
local allGroups = {}

local function newBinding(bindType, actions, modifiers, inputDir, axisDir, bList)
	local b = {
		type = bindType,
		actions = actions,
		modifiers = modifiers,
		value = 0,
		presses = bindType == "button" and 0 or nil,
		inputDir = inputDir, -- Axis limit dir.
		axisDir = axisDir, -- Axis flip.
		parentList = bList -- So it can remove itself.
	}
	return b
end

local function newAction()
	local a = {
		value = 0,
		presses = 0,
		bindings = {} -- Link back to bindings for easy removal.
	}
	return a
end

-- Binding Shortcuts: [optional]
	-- scancode - none/default
	-- key - k:
	-- mouse - m:
	-- joystick/gamepad: j#:

local shortcutToDevice = {
	[""] = "scancode", k = "key", m = "mouse", j = "joy" -- text: no shortcut
}

local function parseCombo(combo)
	combo = string.lower(combo)
	local comboInputs = {}
	-- Use space as a separator since there is no input code with that character (unlike hyphen).
	for inputStr in string.gmatch(combo, "([^% ]+)") do
		local i1,i2,deviceCode,deviceIdx = string.find(inputStr, "(%a+)(%d?):")

		local device = shortcutToDevice[deviceCode] or deviceCode or "scancode"

		local id = inputStr
		if deviceCode then  id = string.sub(inputStr, i2 + 1)  end
		local dir
		if device == "joy" or device == "mouse" then -- Check for sign for gamepad/joystick axes and mouse wheel axes.
			dir = 1
			local preSign, postSign = string.match(id, "([%+%-]?)%w*([%+%-]?)")
			if preSign ~= "" then
				id = string.sub(id, 2)
				dir = preSign == "-" and -1 or 1
			end
			if postSign ~= "" then
				id = string.sub(id, 1, -2)
				dir = dir * (postSign == "+" and 1 or -1)
			end
		end
		if device == "mouse" then
			id = tonumber(id) or id -- For mouse buttons - Love gives the actual number not the string.
		end

		device = device .. (deviceIdx or "")

		table.insert(comboInputs, {device, id, dir})
	end

	local finalInput = table.remove(comboInputs)
	local device, id, dir = finalInput[1], finalInput[2], finalInput[3]

	local modifiers
	if #comboInputs > 0 then  modifiers = comboInputs  end
	return device, id, dir, modifiers
end

local function getBindingList(self, device, id)
	self.allBindings[device][id] = self.allBindings[device][id] or {}
	return self.allBindings[device][id]
end

local function modsAreEqual(modA, modB) -- Check device, id, and dir
	return modA[1] == modB[1] and modA[2] == modB[2] and modA[3] == modB[3]
end

local function modListsAreEqual(modsA, modsB)
	if modsA == modsB then  return true  end -- Both are nil.
	if modsA == nil or modsB == nil then  return false  end -- Only one is nil.
	if #modsA ~= #modsB then  return  end
	for i,modifierA in ipairs(modsA) do
		local bothHave = false
		for i,modifierB in ipairs(modsB) do
			if modsAreEqual(modifierA, modifierB) then
				bothHave = true
				break
			end
		end
		if not bothHave then  return  end
	end
	-- Both have the same length, and all mods in A are found in B: modLists are equal.
	return true
end

local function bindingExists(bindingList, modifiers, bindType, inputDir, axisDir)
	for i,b in ipairs(bindingList) do
		if b.type == bindType and b.inputDir == inputDir and b.axisDir == axisDir then
			if modListsAreEqual(b.modifiers, modifiers) then
				return b, i
			end
		end
	end
end

local function removeFromList(t, val)
	for i=#t,1,-1 do
		local v = t[i]
		if v == val then  table.remove(t, i)  end
	end
end

local function setBindingModifierLinks(self, binding, doLink)
	local modifiers = binding.modifiers
	if modifiers then
		for i,modifier in ipairs(modifiers) do
			local mDevice, mID = modifier[1], modifier[2]
			local links = self.bindingsWithModifier[mDevice][mID]
			if doLink then
				links = links or {}
				table.insert(links, binding)
				self.bindingsWithModifier[mDevice][mID] = links
			elseif links then
				removeFromList(links, binding)
			end
		end
	end
end

local function addBindingToAction(self, actionName, binding)
	local action = self.allActions[actionName] or newAction()
	self.allActions[actionName] = action
	table.insert(action.bindings, binding)
end

local function bindingSorter(a, b) -- Returns true if the first item should come first.
	-- The binding with more modifiers comes first.
	return (a.modifiers ~= nil and #a.modifiers or 0) > (b.modifiers ~= nil and #b.modifiers or 0)
end

local function sortBindingsByModifierCount(bList)
	table.sort(bList, bindingSorter)
end

local function bind(self, bindType, combo, actionName, axisDir)
	assert(actionName, "Input.bind - need to specify an action name.")

	local device, id, inputDir, modifiers = parseCombo(combo)

	local bList = getBindingList(self, device, id)
	local binding = bindingExists(bList, modifiers, bindType, inputDir, axisDir)
	if binding then
		-- If binding for this combo, type, and axisDir exists, just add the new actionName to it.
		table.insert(binding.actions, actionName)
	else
		-- If no matching binding exists, add a new one.
		binding = newBinding(bindType, {actionName}, modifiers, inputDir, axisDir, bList)
		table.insert(bList, binding)
	end
	sortBindingsByModifierCount(bList)

	addBindingToAction(self, actionName, binding) -- Store binding ref on action for easy removal.

	setBindingModifierLinks(self, binding, true) -- Link each modifier back to the binding.
end

local function removeActionBinding(self, actionName, binding)
	local action = self.allActions[actionName]
	assert(action, "Input.removeActionBinding - No action named: '"..tostring(actionName)"' exists.")
	removeFromList(binding.actions, actionName)
	removeFromList(action.bindings, binding)
	if #action.bindings == 0 then  self.allActions[actionName] = nil  end
	if #binding.actions == 0 then
		setBindingModifierLinks(self, binding, false)
		removeFromList(binding.parentList, binding)
	end
end

-- Remove 1 action or all actions from a single combo binding.
local function unbindActionsFromCombo(self, combo, actionName, bindType, axisDir)
	local device, id, inputDir, modifiers = parseCombo(combo)
	local bList = getBindingList(self, device, id)
	local binding, bIndex = bindingExists(bList, modifiers, bindType, inputDir, axisDir)
	if binding then
		if actionName then
			removeActionBinding(self, actionName, binding)
		else -- Remove all actions.
			for i,actionName in ipairs(binding.actions) do
				removeActionBinding(self, actionName, binding)
			end
		end
	end
end

local function unbindAction(self, actionName)
	local action = self.allActions[actionName]
	assert(action, "Input.unbindAction - No action named: '"..tostring(actionName)"' exists.")
	for i,binding in ipairs(action.bindings) do
		removeActionBinding(self, actionName, binding)
	end
end

function group.unbindButton(self, combo, actionName)
	if combo then  unbindActionsFromCombo(self, combo, actionName, "button")
	elseif actionName then  unbindAction(self, actionName)  end
end

function group.unbindAxis(self, combo1, combo2, actionName)
	if actionName and not (combo1 or combo2) then
		unbindAction(self, actionName)
		return
	end
	if combo1 then  unbindActionsFromCombo(self, combo1, actionName, "axis", 1)  end
	if combo2 then  unbindActionsFromCombo(self, combo2, actionName, "axis", -1)  end
end

function group.unbindMouseMoved(self, actionName)
	local actions = self.allBindings.mouse.moved
	if actions then
		removeFromList(actions, actionName)
		self.allActions[actionName] = nil
	end
end

function group.unbindText(self, actionName)
	local actions = self.allBindings.text
	if actions then
		removeFromList(actions, actionName)
		self.allActions[actionName] = nil
	end
end

function group.bindButton(self, combo, actionName)
	bind(self, "button", combo, actionName)
end

function group.bindAxis(self, combo1, combo2, actionName)
	if combo1 then  bind(self, "axis", combo1, actionName, -1)  end
	if combo2 then  bind(self, "axis", combo2, actionName, 1)  end
end

function group.bindMouseMoved(self, actionName)
	self.allBindings.mouse.moved = self.allBindings.mouse.moved or {}
	local action = newAction()
	self.allActions[actionName] = action
	table.insert(self.allBindings.mouse.moved, actionName)
end

function group.bindText(self, actionName)
	local action = newAction()
	self.allActions[actionName] = action
	table.insert(self.allBindings.text, actionName)
end

local bindFuncs = {
	button = group.bindButton, axis = group.bindAxis,
	mouseMoved = group.bindMouseMoved, text = group.bindText
}

function group.bindMultiple(self, t)
	for i,v in ipairs(t) do
		local bindType = v[1]
		local fn = bindFuncs[bindType]
		assert(fn, "input.bindMultiple - No binding function found for binding type '"..tostring(bindType).."'.")
		fn(self, v[2], v[3], v[4])
	end
end

local function rawToButtonVal(input)
	local device, id, dir = input[1], input[2], input[3]
	local val = rawValues[device][id]
	val = val and floor(val + 0.5) or 0
	if dir then  val = max(0, val * dir)  end -- Get an absolute value in the direction we want.
	return val
end

local function modifiersArePressed(modifiers)
	if not modifiers then  return true  end
	for i,mod in ipairs(modifiers) do
		if rawToButtonVal(mod) <= 0 then  return false  end
	end
	return true
end

function group.callAction(self, actionName, value, change, ...)
	return self.stack:call(actionName, value, change, ...)
end

local function buttonHandler(self, binding, newVal, oldVal, isRepeat, x, y, dx, dy, isTouch, presses)
	newVal, oldVal = floor(newVal + 0.5), floor(oldVal + 0.5)
	local change = newVal - oldVal -- -1, 0, or +1
	if change ~= 0 or isRepeat then -- Hack workaround for keyrepeat.
		for i,actionName in ipairs(binding.actions) do
			local action = self.allActions[actionName]
			action.presses = action.presses + change
			action.value = min(1, action.presses)
			local r = self:callAction(actionName, action.value, change, isRepeat, x, y, dx, dy, isTouch, presses)
			if r then  return r  end
		end
	end
end

local function axisHandler(self, binding, newVal, oldVal, isRepeat, x, y, dx, dy, isTouch, presses)
	local change = (newVal - oldVal) * binding.axisDir
	newVal = newVal * binding.axisDir
	if change ~= 0 then
		for i,actionName in ipairs(binding.actions) do
			local action = self.allActions[actionName]
			action.value = action.value + change
			local r = self:callAction(actionName, action.value, change, isRepeat, x, y, dx, dy, isTouch, presses)
			if r then  return r  end
		end
	end
end

local function updateBinding(self, binding, rawVal, ...)
	local bindVal = modifiersArePressed(binding.modifiers) and rawVal or 0
	-- Binding value always positive.
	if binding.inputDir then  bindVal = max(0, bindVal * binding.inputDir)  end
	local bindChange = bindVal - binding.value
	-- Send to handler even if change == 0.
	local handler = binding.type == "button" and buttonHandler or axisHandler
	local consumed = handler(self, binding, bindVal, binding.value, ...)
	binding.value = bindVal
	return consumed
end

function group.mouseMoved(self, x, y, dx, dy)
	local rv = rawValues.mouse.moved
	rv.x, rv.y, rv.dx, rv.dy = x, y, dx, dy
	local actions = self.allBindings.mouse.moved
	if actions then
		for i,actionName in ipairs(actions) do
			local action = self.allActions[actionName]
			action.x, action.y = x, y
			local r = self:callAction(actionName, value, change, isRepeat, x, y, dx, dy, isTouch, presses)
			if r then  return r  end
		end
	end
end

function mouseMoved(x, y, dx, dy)
	for i,group in ipairs(allGroups) do  group:mouseMoved(x, y, dx, dy)  end
end

function group.textInput(self, text)
	rawValues.text.text = text
	local actions = self.allBindings.text
	for i,actionName in ipairs(actions) do
		local action = self.allActions[actionName]
		action.value = text
		local r = self:callAction(actionName, action.value)
		if r then  return r  end
	end
end

function textInput(text)
	for i,group in ipairs(allGroups) do  group:textInput(text)  end
end

function group.rawInput(self, device, id, rawVal, ...)
	for i,obj in ipairs(self.rawStack) do
		obj:call("input", device, id, rawVal, ...)
	end
	-- Update bindings for this input.
	local bindingList = self.allBindings[device] and self.allBindings[device][id]
	if bindingList then
		for i,b in ipairs(bindingList) do
			local consumed = updateBinding(self, b, rawVal, ...)
			if consumed then  break  end
		end
	end
	-- Update any bindings that use this input as a modifier.
	bindingList = self.bindingsWithModifier[device][id]
	if bindingList then
		-- Will only be releasing actions, don't need to consume.
		for i,b in ipairs(bindingList) do  updateBinding(self, b, b.value)  end
	end
end

local function rawInput(device, id, rawVal, ...)
	rawValues[device][id] = rawVal
	for i,group in ipairs(allGroups) do
		group:rawInput(device, id, rawVal, ...)
	end
end

function group.get(self, actionName)
	local action = self.allActions[actionName]
	if action then  return action.value, action.presses  end
end

function group.getRaw(self, device, id)
	return rawValues[device][id] or 0
end

function group.enableRaw(self, obj)
	table.insert(self.rawStack, obj)
end

function group.enable(self, obj, pos)
	self.stack:add(obj, pos)
end

function group.disable(self, obj)
	self.stack:remove(obj)
	removeFromList(self.rawStack, obj)
end


-- Extra arg order: isRepeat, x, y, dx, dy, isTouch, presses
local callbacks = {
	keypressed = function(key, scancode, isRepeat)
		rawInput("key", key, 1, isRepeat)
		rawInput("scancode", scancode, 1, isRepeat)
		local vKey = virtualKeys[key]
		if vKey then
			rawInput("scancode", vKey, 1, isRepeat)
			if not isRepeat then
				virtualKeyPressCount[vKey] = virtualKeyPressCount[vKey] + 1
			end
		end
	end,
	keyreleased = function(key, scancode)
		rawInput("key", key, 0)
		rawInput("scancode", scancode, 0)
		local vKey = virtualKeys[key]
		if vKey then
			local val = virtualKeyPressCount[vKey] - 1
			virtualKeyPressCount[vKey] = val
			rawInput("scancode", vKey, min(1, val)) -- Keep value 0-1.
		end
	end,
	textinput = function(text)
		textInput(text)
	end,
	mousepressed = function(x, y, button, istouch, presses)
		rawInput("mouse", button, 1, nil, x, y, nil, nil, isTouch, presses)
	end,
	mousereleased = function(x, y, button, istouch, presses)
		rawInput("mouse", button, 0, nil, x, y, nil, nil, isTouch, presses)
	end,
	mousemoved = function(x, y, dx, dy, istouch)
		mouseMoved(x, y, dx, dy, istouch)
	end,
	wheelmoved = function(x, y)
		if x ~= 0 then
			rawInput("mouse", "wheelx", sign(x), nil, nil, nil, x, 0) -- value, isRepeat, x, y, dx, dy
			rawInput("mouse", "wheelx", 0, nil, nil, nil, x, 0)
		end
		if y ~= 0 then
			rawInput("mouse", "wheely", sign(y), nil, nil, nil, 0, y)
			rawInput("mouse", "wheely", 0, nil, nil, nil, 0, y)
		end
	end,
	joystickpressed = function(joystick, button)
		rawInput("joy"..joystick:getID(), button, 1)
	end,
	joystickreleased = function(joystick, button)
		rawInput("joy"..joystick:getID(), button, 0)
	end,
	joystickaxis = function(joystick, axis, value)
		rawInput("joy"..joystick:getID(), "axis"..axis, value)
	end,
	joystickhat = function(joystick, hat, dir)
		rawInput("joy"..joystick:getID(), "hat"..hat, dir)
	end,
	gamepadpressed = function(joystick, button)
		rawInput("joy"..joystick:getID(), button, 1)
	end,
	gamepadreleased = function(joystick, button)
		rawInput("joy"..joystick:getID(), button, 0)
	end,
	gamepadaxis = function(joystick, axis, value)
		rawInput("joy"..joystick:getID(), axis, value)
	end,
}

local function newGroup()
	local self = setmetatable({}, group)
	self.allBindings = { key = {}, scancode = {}, text = {}, mouse = {} } -- [device][id] = {binding data...}
	self.bindingsWithModifier = { key = {}, scancode = {}, text = {}, mouse = {} } -- [device][id] = {binding references}
	self.allActions = {} -- [actionName] = {stuff...}
	for i=1,MAX_JOYSTICK_COUNT do
		local k = "joy"..i
		self.allBindings[k], self.bindingsWithModifier[k] = {}, {}
	end
	self.stack = inputStack()
	self.rawStack = {}
	table.insert(allGroups, self)
	return self
end

local function init()
	for name,fn in pairs(callbacks) do
		local oldFn = love[name]
		love[name] = oldFn and function(...)
			oldFn(...)  fn(...)
		end  or fn
	end
end

local Input = newGroup()
Input.init = init
local dontRewrite = { -- These get called by the module with a :
	mouseMoved = true, textInput = true, rawInput = true, callAction = true
}
for k,fn in pairs(group) do
	if dontRewrite[k] then  Input[k] = fn
	else  Input[k] = function(...)  return fn(Input, ...)  end  end -- Allow calling with a .
end
local mt = { __call = newGroup }

return setmetatable(Input, mt)
