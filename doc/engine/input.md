
Input
=====

Converts "raw" inputs to bound "actions" and lets you handle keyboard and gamepad input in a simple, unified way. Can bind 0-or-1 "button" actions or analog -1 to +1 "axis" inputs. Can bind actions to almost any raw input including unlimited input-combos. Binds "text" and "mouseMoved" inputs separately.

Setup
-----

Philtre automatically requires the module into the global: `Input`.

Call init() to hook up the love input callbacks, bind some actions, and enable() input on your objects.

```lua
function love.load()
   Input.init()
   Input.bindAxis("left", "right", "move x")

   scene = SceneTree()

   local myObj = Object()
   Input.enable(myObj)
   -- `myObj` Will need an "input" function (or a script with one)
   -- to actually respond to input.

   scene:add(myObj)
end
```

Input Callback
--------------

The object or one of its scripts must have an "input" function to respond to input. All of the extra raw inputs from the original love callbacks are passed on, so there is a rather long conglomeration of arguments:

> `function input(actionName, value, change, isRepeat, x, y, dx, dy, isTouch, presses)`

All actions will send the `actionName` and most will send `value` and `change`. Text input only sends `value` and not `change`. Mouse movement only sends `x`, `y`, `dx`, and `dy`. Whether any other arguments are present or not will depend on what raw input triggered the action.

* Scancodes and keys will send `isRepeat`.
* Mouse buttons will send `x`, `y`, `isTouch`, and `presses`.
* Mouse wheel movements will send `dx` and `dy`.

Groups
------

Raw input is collected and sent out to any number of group objects. The input module itself is a group and the group methods can be called on it with the . syntax. Each group is completely separate, with its own bindings and actions.

Create a new group by calling the module.
> `local group = Input()`

Binding
-------

Bindings are made with string inputs/input-combos and action names. Each input type (button, axis, text, and mouseMoved) is bound with a separate function.

Each input in a combo is separated by a space and defined by a "device" and an "ID". The device is optional (defaults to scancode) and separated from the ID by a colon(:).

Example:
> `Input.bindButton("ctrl shift m:1", "superClick")`
> `Input.bindButton("j1:leftx-", "left")` -- An optional sign for raw axis inputs.

### Devices

* scancode - The default.
* key - `"key:"` or `"k:"`.
* mouse - `"mouse:"` or `"m:"`.
* joystick or gamepad - `"joy#:"` or `"j#:"`.
   * Replace the `"#"` with the device ID index (1, 2, 3, etc.).

### IDs

The input "ID" is the:
* [Scancode](https://love2d.org/wiki/Scancode)
* [KeyConstant](https://love2d.org/wiki/KeyConstant)
* Mouse button index (a number: 1 = left, 2 = right, 3 = middle, etc.)
* Mouse "wheelx" or "wheely"
* [GamepadButton](https://love2d.org/wiki/GamepadButton)
* [GamepadAxis](https://love2d.org/wiki/GamepadAxis)
* Joystick button (a number)
* Joystick axis ("axis1", "axis2", etc.)
* or joystick hat ("hat1", "hat2", etc.).

There are also a few "virtual" key IDs: "ctrl", "alt", "shift", and "enter". These are combined from the left and right modifier keys, or from "return" and "kpenter" in the case of "enter".

### Direction Sign

Raw inputs that are an axis (mouse wheel, gamepad/joystick axes) will have a direction assigned to them when bound. This can be designated with a "+" or "-" after the ID. The input binding will only respond to that "side" of the axis.

> NOTE: Pushing a gamepad joystick up is negative, down is positive.

### Binding Functions

group:__bindButton(combo, actionName)__

group:__bindAxis(combo1, combo2, actionName)__

`combo1` is for the negative direction, `combo2` for the positive. These both need to be defined, even for joystick axes (for now anywyay).

> `bindAxis("j1:leftx-", "j1:leftx", "player x")`

group:__bindMouseMoved(actionName)__

group:__bindText(actionName)__

group:__bindMultiple(t)__

Takes a sequence of sequences of binding arguments, starting with a "binding type" string—one of the following: "button", "axis", "text", or "mouseMoved", and then the appropriate arguments for that type.

```lua
local bindings = {
   { "button", "enter", "confirm" }
   { "axis", "left", "right", "move x"},
   { "text", "text" },
   { "mouseMoved", "updateCursor" },
}
Input.bindMultiple(bindings)
```

### Un-Binding Functions

Unbinding is pretty similar to binding, but there are a couple of different ways to specify exactly what gets unbound (which are only relevant if you have multiple combos bound to a one action, or vice versa).

1. If both a `combo` and an `actionName` are given, then that action will be unbound from that combo.
2. If only a `combo` is given, then all actions bound to that combo will be unbound.
3. If only an `actionName` is given, then all combos linked to that action will be unbound (but those combos may still be bound to other actions).

group:__unbindButton(combo, actionName)__

group:__unbindAxis(combo1, combo2, actionName)__

group:__unbindMouseMoved(actionName)__

group:__unbindText(actionName)__


### Other Functions

group:__get(actionName)__

Gets the current value of the action, and a current press count for buttons (in case the action has multiple bindings).

group:__getRaw(device, id)__

Gets the latest raw input value for a device and an ID.

group:__enable(obj, pos)__

Enable input for an object. The `pos` argument can be "top", or "bottom" to specify the object's place in the input stack (defaults to "top").

group:__enableRaw(obj)__

Enable raw input on an object. It will get all inputs. This uses a separate list from the usual input stack.

group:__disable(obj)__

Disable normal and raw input for an object.
