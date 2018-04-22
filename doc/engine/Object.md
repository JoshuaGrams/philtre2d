Object
======

The base 'game object' class. Basically an empty transform, plus a few methods that all objects should have.

Constructor
-----------

### Object(x, y, angle, sx, sy, kx, ky)

Methods
-------

### Object.call(self, func_name, ...)
Attempts to call the named function on the object and any scripts that object may have.

### Object.callScripts(self, func_name, ...)
The same as `Object.call`, except it skips the object and only iterates through the object's scripts, if any.

### Object.setPaused(self, paused)
Changes the pause state of the object and calls `setPaused` on the object's scripts. A paused object will not get `update` calls and will prevent them from passing down to its children.

### Object.setVisible(self, visible)
Shows or hides the object and calls `setVisible` on the object's scripts. A hidden object will not draw and will prevent its children from drawing.

### Object.draw(self)
Draws a debug box. I'll probably just delete this later.

Properties
----------

### Object.className
The string name of the class. It uses this as the default `name` of the Object, as well as in Object's `__tostring` metamethod.

Metamethods
-----------

### Object.__tostring()
Returns `'(' .. self.className .. '): path = ' .. tostring(self.path)`. New object classes should set their `.className` property so this will work nicely.

Transform functions
-------------------
`Object` also holds three different transform update functions to be used by itself and any child classes. Every object must have its `.updateTransform` property set to one of these, which will be called by `scene-tree` immediately before the object's children are init, and on every update immediately after the object's `update` is called.

### Object.TRANSFORM_REGULAR(self)
The default. Sets the object's `_to_world` matrix to its parent's `_to_world` multiplied by its own, updated, local transform.

### Object.TRANSFORM_ABSOLUTE(self)
For dynamic and static physics objects. Keeps the object in world coordinates, ignoring the parent's transform entirely.

### Object.TRANSFORM_PASS_THROUGH(self)
For 'collection'-style objects that should never have a transform of their own. Copies its parent's `_to_world` matrix onto itself.