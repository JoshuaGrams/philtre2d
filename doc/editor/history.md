History
=======

A history is a list of commands which have been performed and a
dictionary of the command types that it knows how to do/undo.

	local History = require 'history'
	local h = History.new()

Start by registering commands, associating their names with
the appropriate functions.

* `h:command(name, perform, revert, update)`

	* `perform(performArgs) -> undoArgs`

	* `revert(undoArgs)`

	* `update(...) -> performArgs`

The `perform` function is used both to perform the command in
the first place and to redo it.  The `revert` function is used
to undo a command.  The optional `update` function is for
implementing interactive commands (move, resize, etc.) where you
want to modify the arguments of the command that's already in
the history instead of adding a million tiny move commands.

----

Once you have registered your commands, you can use the history
methods:

* `h:perform(name, args...) -> undoArgs` - Perform a command and
  add it to the history.

* `h:undo()` - Undo the most recent command (if any).

* `h:redo()` - Redo the next command (if any).

* `h:update(args...)` - Pass args to the current command's
  `update` method (which may or may not take the same arguments
  as the `perform` method).

* `h:cancel()` - Cancels the most recent command, removing it
  completely.

----

Note that we do not forget future commands when you perform a
new one, we simply shift them to an alternate future.  So you
can ask how many futures there are with `futureCount` and choose
one with `chooseFuture`.

* `h:futureCount() -> number`

* `h:chooseFuture(number)`

----

If you undo/redo the creation of an object, it will most likely
create a different object.  If the argument lists for subsequent
commands refer directly to the old object (which doesn't exist
in the world any more) then they will no longer do anything
useful.

You *could* come up with some scheme to refer to objects
indirectly, and ensure that if you undo/redo creation, it always
creates an object with the same reference.  Or you could
register selection functions and have your argument lists invoke
those to select the object(s) to operate on.

* `h:selector(fn)` - Register `fn` as a selector function.  Now
  when `fn` is encountered in argument lists, the function will
  be invoked on the following argument, and its return value(s)
  will be used.


```lua
-- pickObject(x, y) -> object under point.
h:selector(pickObject)

-- selection(n) -> nth most recent selection.
h:selector(selection)

-- Get object as if you clicked at (100, 230) and make it 50% bigger.
h:perform('resize',  pickObject, {100,230},  1.5)

-- Get most recently selection and make it 25% smaller.
h:perform('resize',  selection, 1,  0.75)
```
