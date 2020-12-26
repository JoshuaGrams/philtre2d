Scene Tree
==========

The scene tree tracks objects and manages transforms and local coordinates for child objects. It manages updating all its child objects and adding  and removing them from the draw order.

Basic Usage
-----------

Create a scene tree with `SceneTree(layer_groups, [default_layer])`. It passes its arguments to the [`drawOrder`](draw-order.md) constructor.  Call `scene:update(dt)` from `love.update` and `scene:draw(layer_group_names)` from `love.draw`.

Other than that, all you need to use the scene tree are `scene:add(object, [parent])`, and `scene:remove(object)`. All objects in the scene tree should extend Object. The scene tree is dependent on some of Object's properties and methods, particularly `call`, `updateTransform`, and `_to_world`.

Each scene tree creates its own draw order, which can be accessed at `scene.draw_order`.

Functions
---------

### scene:add(obj, [parent])
Adds an object to the tree. If no parent is specified it will be added at the root level (a child of the tree object). Each object added to the tree will be given the following properties:
 * `tree`: A reference to the SceneTree object.
 * `parent`: Its parent object reference.
 * `name`: Its existing name or a generated one, will be used in its `path`.
 * `_index`: Its child index.
 * `path`: Its address in the tree, used with `scene:get(path)`. You can use the `path` to check if an object is in the tree, since it will be cleared when the object is removed.

Once the object and any children are added to the tree, `init` is called on each object, in bottom-up order.

_PARAMETERS_
* __obj__ <kbd>Object</kbd> - The object to add.
* __parent__ <kbd>Object</kbd> - _optional_ - The parent object to add it to. This defaults to the scene tree root if nothing is specified.

### scene:remove(obj)
Removes the object from the tree. This will also remove the object's children down the tree. The object and its children will not be drawn or updated after this, they will just get a `final` callback. Removed branches of objects will remain intact, they can be re-added to the tree if desired.

_PARAMETERS_
* __obj__ <kbd>Object</kbd> - The object to remove.

### scene:update(dt)
Updates the whole scene tree. This will call the `update` method of each object. Then it will call `final` on any removed objects and complete pending reparentings.

_PARAMETERS_
* __dt__ <kbd>number</kbd> - Delta time for this frame.

### scene:draw([layerGroups])
Calls `updateTransform` on all objects, and draws the given `layerGroups`.

Example:
```lua
-- If you have a single list of layers, no layerGroups:
scene:draw() -- draws all layers

-- With layerGroups 'game' and 'gui', changing state in between:
Camera.current:applyTransform()
scene.draw_order:draw('game')
Camera.current:resetTransform()
scene.draw_order:draw('gui')

-- With layerGroups 'game' and 'gui', drawing both at once:
scene:draw({'game', 'gui'})
```

### scene:get(path)
Gets the object at the specified path.

_PARAMETERS_
* __path__ <kbd>string</kbd> - Path to the object to get.

_RETURNS_
* __obj__ <kbd>Object | nil</kbd> - The object at the specified path (or `nil` if none is found).

### scene:setParent(obj, [parent], [keepWorldTransform])
Moves an object in the scene tree from its current parent to another.

_PARAMETERS_
* __obj__ <kbd>Object</kbd> - The object to reparent.
* __parent__ <kbd>Object</kbd> - _optional_ - The object to reparent `obj` to. Defaults to the scene tree root.
* __keepWorldTransform__ <kbd>bool</kbd> - _optional_ - Modify the object's local coordinates so that its world coordinates stay the same. Only has an effect for objects with `TRANSFORM_REGULAR`.
