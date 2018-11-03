Scene Tree
==========

The scene tree tracks objects and manages transforms and local coordinates for child objects. It manages updating all its child objects and adding them to the draw order. This module is 'stateful'. There is only one scene tree.

Basic Usage
-----------

Give the scene tree a draw order with `scene.init(DrawOrder)`, and add `scene.update()` and `scene.draw()` in `love.update()` and `love.draw()`, respectively.

Other than that, all you need to use the scene tree are `scene.add(object, [parent])`, and `scene.remove(object)`. All objects in the scene tree should extend Object. The scene tree is dependent on some of Object's properties and methods, particularly `call`, `updateTransform`, and `_to_world`. Scene tree will give each object `name`, `path`, and `parent` properties on init.

Functions
---------

### scene.init(draw_order)
A bit silly, this just gives scene tree a reference to a draw order. Possibly scene tree should make its own draw order in the future.

_PARAMETERS_
* __draw_order__ <kbd>DrawOrder</kbd> - The DrawOrder for the scene tree to use.

### scene.add(obj, [parent])
Adds an object to the tree. If no parent is specified it will be added at the root level (a child of the tree object). This will add the object to its parent's child list and init the object, setting its path, parent, initializing its children, and finally calling 'init' on the object and its scripts.

_PARAMETERS_
* __obj__ <kbd>Object</kbd> - The object to add.
* __parent__ <kbd>Object</kbd> - _optional_ - The parent object to add it to. This defaults to the scene tree root if nothing is specified.

### scene.remove(obj)
Removes the object from the tree. This will also remove the object's children down the tree. The object and its children will not be drawn or updated after this, they will just get a 'final' callback.

_PARAMETERS_
* __obj__ <kbd>Object</kbd> - The object to remove.

### scene.update(dt)
Updates the whole scene tree. For each object this will call `update`, `updateTransform`, and add the object to the draw order.

_PARAMETERS_
* __dt__ <kbd>number</kbd> - Delta time for this frame.

### scene.draw()
If a draw order is known, this calls it's `draw` function, otherwise it draws everything in the tree in parent --> child order (obsolete).

### scene.get(path)
Gets the object at the specified path.

_PARAMETERS_
* __path__ <kbd>string</kbd> - Path to the object to get.

_RETURNS_
* __obj__ <kbd>Object | nil</kbd> - The object at the specified path (or `nil` if none is found).

### scene.toWorld(obj, x, y, [w])
Transforms a vector, local to `obj`, into world coordinates.

_PARAMETERS_
* __obj__ <kbd>number</kbd> - The Object whose transform to use.
* __x__ <kbd>number</kbd> - Local x.
* __y__ <kbd>number</kbd> - Local y.
* __w__ <kbd>number</kbd> - _optional_ - Local w. Defaults to 1.

_RETURNS_
* __x__ <kbd>number</kbd> - World x.
* __y__ <kbd>number</kbd> - World y.

### scene.toLocal(obj, x, y, [w])
Transforms a world vector into coordinates local to `obj`.

_PARAMETERS_
* __obj__ <kbd>number</kbd> - The Object whose transform to use.
* __x__ <kbd>number</kbd> - World x.
* __y__ <kbd>number</kbd> - World y.
* __w__ <kbd>number</kbd> - _optional_ - World w. Defaults to 1.

_RETURNS_
* __x__ <kbd>number</kbd> - Local x.
* __y__ <kbd>number</kbd> - Local y.

### scene.setParent(obj, [parent])
Moves an object in the scene tree from its current parent to another. Behind the scenes, this happens in two parts. The object's parent reference is changed immediately to the new parent, so it will inherit the new parent's transform for drawing & positioning, but it's kept in the same child list so none of its `update` or other callbacks get messed up. At the next pre- or post-update the reparenting is completed, swapping the object out of its old parent's child list into the new one's.

_PARAMETERS_
* __obj__ <kbd>Object</kbd> - The object to reparent.
* __parent__ <kbd>Object</kbd> - _optional_ - The object to reparent `obj` to. Defaults to the scene tree root.
