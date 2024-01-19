Scene Tree
==========

The scene tree tracks objects and manages transforms and local coordinates for child objects. It manages updating all its child objects and adding  and removing them from the draw order.

Basic Usage
-----------

Create a scene tree with

    local scene = SceneTree(layer_groups, [default_layer])

It passes its arguments to the [`drawOrder`](draw-order.md) constructor.

From `love.update` call:

    scene:update(dt)


From `love.draw` call:

    scene:updateTransforms()
    scene:draw(layer_group_names)

Then use `scene:add(object, [parent])` and `scene:remove(object)` to add and remove objects from the tree. All objects in the scene tree should extend Object. The scene tree is dependent on some of Object's properties and methods, particularly `call`, `updateTransform`, and `_toWorld`.

Each scene tree creates its own draw order, which can be accessed at `scene.drawOrder`.

Iterating Over Children
-----------------------

To simplify the creation of short unique paths for all objects, the child lists of objects (i.e. `obj.children`) can have "holes" (nil values) in them if objects have been deleted. This means that iteration over the list with ipairs may not find all (or any) of the children. Two global helper functions, `everychild` and `forchildin` are included with Philtre to make iteration easier.

Once the object is added to a scene-tree, the index of its last child is stored on the children list as the property `maxn`.

### everychild( children )
An iterator function that can be used in place of ipairs. Note that the indices it returns may not be consecutive.

> If the `maxn` property does not exist on `children`, this function will set it to `#children`.

```lua
for i,child in everychild(self.children) do
   -- do stuff
end
```

### forchildin( children, fn )
A function that takes a function (`fn`) as an argument, which it will call once for each child in the list (`children`). The index and child object will be passed to the function.

```lua
local function do_stuff(i, child)
   -- do stuff
end

function M.init(self) -- Or wherever...
   forchildin(self.children, do_stuff)

   -- Or, with an anonymous function:
   forchildin(self.children, function(i, child)  print(i, child)  end)
end
```

### Manual Iteration
If you are very concerned about performance optimization, you can use `maxn` to iterate with a numeric `for` loop.

```lua
-- Need to use #children if not added to the tree yet.
for i=1,children.maxn or #children do
   local child = children[i]
   if child then -- May be a 'hole'/nil, so you must check it.
      -- do stuff
   end
end
```

Functions
---------

### scene:add(obj, [parent], [atIndex])
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
* __atIndex__ <kbd>number</kbd> - _optional_ - The index at which to insert the object into the parent's child list. Must be > 0. Only needed if you specifically want to modify the child order. May modify the paths of any objects with non-unique names from this index up until the next empty space in the list. Doesn't affect the draw-order.

### scene:remove(obj)
Removes the object from the tree. This will also remove the object's children down the tree. The object and its children will not be drawn or updated after this, they will just get a `final` callback. Removed branches of objects will remain intact, they can be re-added to the tree if desired.

_PARAMETERS_
* __obj__ <kbd>Object</kbd> - The object to remove.

### scene:swap(parent, i1, i2)
Swaps the positions of two items in a parent's child list. Will change the children's paths if they have non-unique names. Doesn't affect the draw-order.

_PARAMETERS_
* __parent__ <kbd>Object</kbd> - The parent whose children to swap.
* __i1__ <kbd>number</kbd> - The index of the first child to swap.
* __i2__ <kbd>number</kbd> - The index of the second child to swap.

### scene:setParent(obj, [parent], [keepWorldTransform])
Moves an object in the scene tree from its current parent to another.

_PARAMETERS_
* __obj__ <kbd>Object</kbd> - The object to reparent.
* __parent__ <kbd>Object</kbd> - _optional_ - The object to reparent `obj` to. Defaults to the scene tree root.
* __keepWorldTransform__ <kbd>bool</kbd> - _optional_ - Modify the object's local coordinates so that its world coordinates stay the same. Only has an effect for objects with `TRANSFORM_REGULAR`.

### scene:get(path)
Gets the object at the specified path.

_PARAMETERS_
* __path__ <kbd>string</kbd> - Path to the object to get.

_RETURNS_
* __obj__ <kbd>Object | nil</kbd> - The object at the specified path (or `nil` if none is found).

### scene:update(dt)
Updates the whole scene tree. This will call the `update` method of each object.

_PARAMETERS_
* __dt__ <kbd>number</kbd> - Delta time for this frame.

### scene:updateTransforms()
Updates all objects' world transforms from their local transforms so they are ready to be drawn in the correct positions. Recursively calls `updateTransform` on all objects in the tree.

### scene:draw([layerGroups])
Draws the visible objects in the tree. If you have layer groups defined then you must specify a group to draw.

Example:
```lua
-- If you have a single list of layers, no layerGroups:
scene:draw() -- draws all layers

-- With layerGroups 'game' and 'gui', changing state in between:
Camera.current:apply()
scene.drawOrder:draw('game')
Camera.current:reset()
scene.drawOrder:draw('gui')

-- With layerGroups 'game' and 'gui', drawing both at once:
scene:draw({'game', 'gui'})
```
