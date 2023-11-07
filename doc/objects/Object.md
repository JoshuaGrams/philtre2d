Object
======

The base 'game object' class. Basically an empty transform, plus a few methods that all objects should have.

Constructor
-----------

### Object(x, y, angle, sx, sy, kx, ky)

Inheriting Object
-----------------

```lua
-- `Object` is defined globally in philtre.init.
local MyClass = Object:extend()
```

Object does not have most of the "lifecycle" methods (init, final, update, and draw), only updateTransform and set. So for most purposes, the only 'super' method you may want to call is 'set'.

```lua
function MyClass.set(self, x, y, myArg1, myArg2)
   MyClass.super.set(self, x, y)
   -- Do MyClass constructor stuff.
end
```

Properties
----------

### Local Transform Properties
These don't have to exist, but the scene-tree and some other modules will use them if they do.
* **pos** - Position, {x=0, y=0}.
* **sx, sy** - Scale x and y.
* **angle** - Rotation angle in radians, clockwise.
* **kx, ky** - Skew (or "shear") x and y. Default: 0, 0.

### Misc Properties
* **timeScale** - Delta-time multiplier for this object and its descendants. Set to 0 to pause. Set to `nil` or 1 to do nothing.
* **visible** - If this object is set visible or hidden (thus hiding all its children). Do NOT modify this value directly, use `Object.setVisible` instead.
* **drawIndex** - This object's index within its draw layer. Do NOT modify this value directly. Will be `nil` if the object is not being drawn (if it or any of its ancestors is hidden). Can be used to check if this object is currently being drawn, or if it will be drawn above or below another object in the same layer. Objects with higher indices are drawn later (i.e., on top).

### Scene-tree Properties
Scene-tree will add these to all objects when they are added to the tree.
* **name** - The object's name. Doesn't have to be unique. Can be pre-set by the user, or will be set to the Object's class name.
* **path** - A string identifier for this object in the tree. Parent's path .. / .. this object's name. An index number will be added to the end if necessary to ensure unique paths.
* **tree** - A reference to the scene-tree root.
* **parent** - A reference to this object's parent.

#### Optional
 * **children** - A list of references to this object's children.
 * **scripts** - A list of references to this object's scripts. The user can set this to a single reference, but scene-tree will convert it to a list when it's added to the tree.

Methods
-------

### Object.setVisible(self, visible)
Will show or hide the object. Invisible objects and their children will not be drawn, but they will still get `updateTransform` and `update` calls.

### Object.call(self, fnName, ...)
Attempts to call the named function on the object and any scripts that object may have.

### Object.callRecursive(self, isTopDown, fnName, ...)
Recursively calls `Object.call` on the object and all of its descendants. If `isTopDown` is true then parents are always called before children, otherwise it is from the bottom up—children are called before their parents (with self being last).

### Object.debugDraw(self, layer)
Unused by default. Uses `tree.drawOrder:addFunction` to draw debug stuff to the specified layer. Can be used on the whole scene-tree with `Object.callRecursive`. The debugDraw function will _not_ be automatically removed from the layer later, so you probably want to clear your debug layer every frame.
```lua
-- Inside love.draw():
scene.drawOrder:clear("physics debug")
scene:callRecursive("debugDraw", false, "physics debug")
-- scene:draw("world") etc...
```

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
`Object` also holds three different transform update functions to be used by itself and any child classes. Objects in the Scene-Tree must have a `.updateTransform` method to update their `_toWorld` matrix, which the Scene-Tree will call on all objects before the `draw` callback.

### Object.TRANSFORM_REGULAR(self)
The default. Sets the object's `_toWorld` matrix to its parent's `_toWorld` multiplied by its own, updated, local transform.

### Object.TRANSFORM_ABSOLUTE(self)
For dynamic and static physics objects. Keeps the object in world coordinates, ignoring the parent's transform entirely.

### Object.TRANSFORM_PASS_THROUGH(self)
For 'collection'-style objects that should never have a transform of their own. Copies its parent's `_toWorld` matrix onto itself.
