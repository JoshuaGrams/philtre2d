Object
======

The base 'game object' class. Basically an empty transform, plus a few methods that all objects should have.

Constructor
-----------

### Object(x, y, angle, sx, sy, kx, ky)

Properties
----------

### Local Transform Properties
These don't have to exist, but the scene-tree and some other modules will use them if they do.
* **pos** - Position, {x=0, y=0}.
* **sx, sy** - Scale x and y.
* **angle** - Rotation angle in radians, clockwise.
* **kx, ky** - Skew x and y.

### Misc Properties
* **paused** - If the object (and its children) will get updates or not. It's recommended to use `obj:setPaused(paused)` instead of changing this directly. 
* **visible** - If the object (and its children) will be drawn or not. It's recommended to use `obj:setVisible(visible)` instead of changing this directly.

### Scene-tree Properties
Scene-tree will add these to all objects when they are added to the tree.
* **name** - The object's name. Doesn't have to be unique. Can be pre-set by the user, or will be set to the Object's class name.
* **path** - A string identifier for this object in the tree. Parent's path .. / .. this object's name. An index number will be added to the end if necessary to ensure unique paths.
* **tree** - A reference to the scene-tree root.
* **parent** - A reference to this object's parent.

#### Optional
 * **children** - A list of references to this object's children.
 * **script** - A list of references to this object's scripts. The user can set this to a single reference, but scene-tree will convert it to a list when it's added to the tree.

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

### Object.toWorld(obj, x, y, [w])
Transforms a vector, local to `obj`, into world coordinates.

_PARAMETERS_
* __obj__ <kbd>number</kbd> - The Object whose transform to use.
* __x__ <kbd>number</kbd> - Local x.
* __y__ <kbd>number</kbd> - Local y.
* __w__ <kbd>number</kbd> - _optional_ - Local w. Defaults to 1.

_RETURNS_
* __x__ <kbd>number</kbd> - World x.
* __y__ <kbd>number</kbd> - World y.

### Object.toLocal(obj, x, y, [w])
Transforms a world vector into coordinates local to `obj`.

_PARAMETERS_
* __obj__ <kbd>number</kbd> - The Object whose transform to use.
* __x__ <kbd>number</kbd> - World x.
* __y__ <kbd>number</kbd> - World y.
* __w__ <kbd>number</kbd> - _optional_ - World w. Defaults to 1.

_RETURNS_
* __x__ <kbd>number</kbd> - Local x.
* __y__ <kbd>number</kbd> - Local y.

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
