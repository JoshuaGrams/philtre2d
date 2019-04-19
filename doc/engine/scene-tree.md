Scene Tree
==========

The scene tree tracks objects and manages transforms and local coordinates for child objects. It manages updating all its child objects and adding them to the draw order. This module is 'stateful'. There is only one scene tree.

Basic Usage
-----------

Create a scene tree with `Scene(layer_groups, [default_layer])`. It passes its arguments to the [`drawOrder`](draw-order.md) constructor.  Call `scene:update(dt)` and `scene:draw(layer_group_names)` from `love.update` and `love.draw`, respectively.

Other than that, all you need to use the scene tree are `scene:add(object, [parent])`, and `scene:remove(object)`. All objects in the scene tree should extend Object. The scene tree is dependent on some of Object's properties and methods, particularly `call`, `updateTransform`, and `_to_world`. Scene tree will give each object `name`, `path`, `parent`, and `tree` properties on init.

Functions
---------

### SceneTree.add(tree, obj, [parent])
Adds an object to the tree. If no parent is specified it will be added at the root level (a child of the tree object). This will add the object to its parent's child list and init the object, setting its path, parent, initializing its children, and finally calling 'init' on the object and its scripts.

_PARAMETERS_
* __obj__ <kbd>Object</kbd> - The object to add.
* __parent__ <kbd>Object</kbd> - _optional_ - The parent object to add it to. This defaults to the scene tree root if nothing is specified.

### SceneTree.remove(tree, obj)
Removes the object from the tree. This will also remove the object's children down the tree. The object and its children will not be drawn or updated after this, they will just get a 'final' callback.

_PARAMETERS_
* __obj__ <kbd>Object</kbd> - The object to remove.

### SceneTree.update(tree, dt)
Updates the whole scene tree. This will call the `update` method of each object. Then it will call `final` on any removed objects, complete pending reparentings, then `updateTransform` on all remaining objects and add them to the draw order.

_PARAMETERS_
* __dt__ <kbd>number</kbd> - Delta time for this frame.

### SceneTree.draw(tree, layerGroups)
Calls `updateTransform` on all objects, collects the visible objects into the draw order, and `draw`s the given `layerGroups`.

### SceneTree.get(tree, path)
Gets the object at the specified path.

_PARAMETERS_
* __path__ <kbd>string</kbd> - Path to the object to get.

_RETURNS_
* __obj__ <kbd>Object | nil</kbd> - The object at the specified path (or `nil` if none is found).

### SceneTree.setParent(tree, obj, [parent], [keepWorld], [now])
Moves an object in the scene tree from its current parent to another. Behind the scenes, this happens in two parts. The object's parent reference is changed immediately to the new parent, so it will inherit the new parent's transform for drawing & positioning, but it's kept in the same child list so none of its `update` or other callbacks get messed up. At the next pre- or post-update the reparenting is completed, swapping the object out of its old parent's child list into the new one's.

_PARAMETERS_
* __obj__ <kbd>Object</kbd> - The object to reparent.
* __parent__ <kbd>Object</kbd> - _optional_ - The object to reparent `obj` to. Defaults to the scene tree root.
* __keepWorld__ <kbd>bool</kbd> - _optional_ - Modify the object's local coordinates so that its world coordinates stay the same. Only has an effect for objects with `TRANSFORM_REGULAR`.
* __now__ <kbd>bool</kbd> - _optional_ - Move the object immediately. This may cause it to get two callbacks for the current frame, or none at all.
