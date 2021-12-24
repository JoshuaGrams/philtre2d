
# Input

Converts "raw" inputs to bound "actions" and lets you handle keyboard and mouse buttons and gamepad input in a unified way. Can bind 0-or-1 "button" actions or analog -1 to +1 "axis" inputs. Typed "text" and mouse "cursor" movement are bound as their own action types.

Philtre automatically requires the module into the global: `Input`.

__Table of Contents:__
- [Quick Start](#quick-start)
- [Subscribing to Input](#subscribing-to-input)
- [Binding](#binding)
	- [Action Types](#action-types)
	- [Defining Raw Inputs](#defining-raw-inputs)
		- [Devices](#devices)
		- [IDs](#ids)
	- [Input.bind()](#inputbind)
- [Input Callback](#input-callback)
	- [Consuming Input](#consuming-input)
	- [Raw Input Callback](#raw-input-callback)
- [Un-Binding](#un-binding)
- [Querying Input](#querying-input)

## Quick Start

1. Call `Input.init()` to hook up the love input callbacks.
2. Use `Input.bind` to bind some actions.
3. Call `Input.enable(obj)` to subscribe to input on an object.
4. Add an `input` method on your object to receive input.

```lua
-- Object setup:
local myObj = Object()

function myObj.input(self, action, value, change, ...)
	if action == "move x" then
		self.vx = value * 100
	elseif action == "fire" and change == 1 then
		-- Fire a bullet.
	end
end

function love.load()
	Input.init()
	Input.bind("axis", "left", "right", "move x")
	Input.bind("button", "z", "fire")
	Input.bind("cursor", "mouse moved")
	Input.bind("text", "text input")

	scene = SceneTree()

	Input.enable(myObj)
	scene:add(myObj)
end
```
## Subscribing to Input

To get input events you need an object that you subscribe to input with. It doesn't have to be an `Object` in the scene tree, it can be any table with the appropriate [callback](#input-callback).

Input events are distributed to objects using an input stack. Objects higher in the stack get input before lower ones. Any object or object's script can return `true` from it's input callback to consume input and prevent the event from reaching objects lower on the stack.

##### Input.enable(object, [index])
Adds the object to the input stack. By default, new objects are added to the top of the stack.

An `index` can be given to insert it into a different position on the stack. If `index` is positive, it's treated as an absolute index, with `1` being the bottom of the stack. If `index` is zero or a negative number, then it's treated as an offset from the top of the stack, so `-1` is just underneath the top object.

##### Input.disable(object)
Removes the object from the input stack. Don't forget to call this when you destroy objects with input enabled.

##### Input.enableRaw(object, [index])
Adds the object to a separate stack that receives raw input events. Raw input events are received just before the regular input event (if any), via a separete `rawInput` callback.

##### Input.disableRaw(object)
Removes the object from the raw-input stack.

## Binding

Binding connects raw/physical inputs with named "actions". Any number of raw inputs can be bound to a single action, and a single raw input can be bound to any number of actions.

### Action Types
There are four available action types: "__button__", "__axis__", "__text__", and "__cursor__".

You can bind a raw input to different action types at the same time, but each action name can only have one action type. For example: you can't have an action named "fire" be both a "button" and a "text" action.

##### "button"
An on-or-off, 0-or-1, pressed-or-released action. If you bind an analog joystick input to a button action, it will be considered "pressed" when the axis value is greater than or equal to 0.5.

##### "axis"
An analog, -1-to-+1 action. Each half (positive and negative) of the axis can be bound to separate raw inputs.

##### "text"
For typed text character input. A "text" action is a special case, you don't specify a raw input for it, only an action name to bind it to.

##### "cursor"
For movement of the mouse cursor. Like a "text" action, you don't specify a raw input, only an action name. A "cursor" action is always bound to mouse movement.

### Defining Raw Inputs

Raw inputs for "button" and "axis" bindings are specified by a string with two parts: the "device" (mouse, keyboard, etc), and the "ID" of the specific control. For example:

> `"key:b"`

or

> `"joy2:leftx+"`

The first part, before the colon, denotes the device, and the part after the colon is the ID.

Each half of an axis input like the mouse wheel or a joystick axis is considered a separate input and the sign (+/-) _must_ be specified.

> NOTE: Pushing a gamepad joystick up is negative, down is positive.

#### Devices

* scancode - The default—no device specified.
* key - `"key:"` or `"k:"`.
* mouse - `"mouse:"` or `"m:"`.
* joystick or gamepad - `"joy#:"` or `"j#:"`.
   * Replace the `"#"` with the device ID index (1, 2, 3, etc.).

#### IDs

The input "ID" is the:
* [Scancode](https://love2d.org/wiki/Scancode)
* [KeyConstant](https://love2d.org/wiki/KeyConstant)
* Mouse button index (a number: 1 = left, 2 = right, 3 = middle, etc.)
* Mouse wheel: "wheelx+", "wheelx-", "wheely+", or "wheely-"
* [GamepadButton](https://love2d.org/wiki/GamepadButton)
* [GamepadAxis](https://love2d.org/wiki/GamepadAxis) (plus the sign (+/-))
* Joystick button (a number)
* Joystick axis ("axis1", "axis2", etc.) (plus the sign (+/-))
* or joystick hat name, axis, and sign ("hat1x+", "hat2y-", etc.).

### Input.bind()

##### Input.bind("button", inputStr, actionName)

##### Input.bind("axis", inputStrNeg, inputStrPos, actionName)

##### Input.bind("text" or "cursor", actionName)
Typed "text" input and mouse "cursor" movement are their own special cases. They directly correspond to specific raw inputs, so you don't need an device and ID to bind them.

##### Input.bind(table)
Make multiple bindings at once by providing a list of tables with the arguments for each binding.

```lua
local bindings = {
   { "button", "enter", "confirm" }
   { "axis", "left", "right", "move x"},
   { "text", "text" },
   { "cursor", "mouse moved" },
}
Input.bind(bindings)
```

## Input Callback

The object or one of its scripts must have an "input" function to respond to input. All of the extra raw inputs from the original love callbacks are passed on, so there is a rather long conglomeration of arguments:

> `function input(action, value, change, rawChange, isRepeat, x, y, dx, dy, isTouch, presses)`

All actions will send the `action` and most will send `value`, `change`, and `rawChange`. Text input only sends `value` and not `change`. Mouse movement only sends `x`, `y`, `dx`, and `dy`. Whether any other arguments are present or not will depend on what raw input triggered the action.

* Scancodes and keys will send `isRepeat`.
* Mouse buttons will send `x`, `y`, `isTouch`, and `presses`.
* Mouse wheel movements will send `dx` or `dy`.

_PARAMETERS_
* __`value`__ - The current action value. Is 0 or 1 for button inputs and -1 to +1 for axis inputs.
* __`change`__ - The change in value since the last input. Will be +1 for button presses and -1 for button releases, or 0 for key-repeat inputs.
* __`rawChange`__ - Will match `change` unless you have multiple raw inputs bound to the same action. For example: If you have two keys bound to the same "button" action, and you press both, the first press will give `change = 1` and the second will give `change = 0`, but the `rawChange` for both will be 1. Key-repeat inputs will have a `rawChange` of 0.

#### Consuming Input

If any object or script returns `true` from its `input` method then that input event will be "consumed". The call will stop going down the stack, and no other objects or scripts will receive that event.

#### Raw Input Callback

> `function rawInput(device, id, value, change, isRepeat, x, y, dx, dy, isTouch, presses)`

## Un-Binding

There are a couple of different ways to specify exactly what action or raw input you want to un-bind (which generally only matter if you have multiple combos bound to a one action, or vice versa).

##### Input.unbindAction(actionName)
Unbinds all raw inputs from this action.

##### Input.unbindInput(device, id)
Unbinds this device and ID from all actions.

You must specify the full `device` name: "scancode", "key", "mouse", "text", "joy1", "joy2", etc.

"text" actions use the `device` and `id`: "text", "text".
"cursor" actions use the `device` and `id`: "mouse", "moved".

##### Input.unbindFromAction(device, id, actionName)
Unbinds only this device and ID from this action.

## Querying Input

You don't have to subscribe to input to make queries, which may matter if you want to pause objects that are using input.

##### Input.get(actionName)

_RETURNS:_

* __`value`__ - The action's current value.
* __`total`__ - The action's current _cumulative_ value (in case the action has multiple bindings). For example: if you have three keys bound to an action and they are all pressed, the cumulative value will be 3. Or if you have two joysticks bound to an axis and one is pressed all the way down and the other is pressed halfway down, the `total` will be 1.5 (while the `value` is clamped to 1).

##### Input.getRaw(device, id)
Returns the raw value stored for this device and ID, or `nil` if no input has been received yet for that device and ID.

You must specify the full `device` name: "scancode", "key", "mouse", "text", "joy1", "joy2", etc.

"text" actions use the `device` and `id`: "text", "text".
"cursor" actions use the `device` and `id`: "mouse", "moved".

##### Input.isPressed(actionName)
For button actions, returns `true` or `false`. Always returns `nil` for other action types.

##### Input.getInputs(actionName)
Returns `nil` or a list of tables: `{ {device=, id=}, ... }`.

##### Input.getActions(device, id)
Returns `nil` or a list of tables: `{ {name=, flipAxis=}, ... }`.

You must specify the full `device` name: "scancode", "key", "mouse", "text", "joy1", "joy2", etc.

"text" actions use the `device` and `id`: "text", "text".
"cursor" actions use the `device` and `id`: "mouse", "moved".
