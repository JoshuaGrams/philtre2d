Physics
=======

A physics utility module. Helps manage named collision groups so you don't have to remember arbitrary numbers.

> Note: Here and in `Body`, I use the term 'group', but I'm actually talking about what Box2D calls 'categories'. Box2D's 'group index' feature seems pretty unnecessary, so I ignored it, and the word 'group' is a lot shorter than 'category'.

Module Functions
----------------

### physics.set_groups(...)
Saves a table mapping string names to physics category indices (1-16). Pass in up to 16 different strings (as individual arguments).

### physics.groups(...)
Gets a list of group indices from mapped group names. Pass in up to 16 different strings (as individual arguments).

_RETURNS_
* __groups__ <kbd>table</kbd> - A table of category indices corresponding to the group names given. You can give this directly to the `Body` constructor for a shape's 'groups' or 'masks' property, or the `Body.setMask` method.

### physics.groups_except(...)
Gets the opposite of `physics.groups`: a list of all group indices _except_ the ones corresponding to the group names given. Pass in up to 16 different strings (as individual arguments).

_RETURNS_
* __groups__ <kbd>table</kbd> - A table of category indices corresponding to all the group names _not_ given. You can give this directly to the `Body` constructor for a shape's 'groups' or 'masks' property, or the `Body.setMask` method.

### physics.group_index(group_name)
Gets the corresponding index of a named group. Can be useful for checking collision results.

_PARAMETERS_
* __group_name__ <kbd>string</kbd> - The physics group name to get the matching index of.

_RETURNS_
* __index__ <kbd>number</kbd> - The group index.
