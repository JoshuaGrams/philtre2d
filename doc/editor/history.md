History
=======

A history is a list of commands which have been performed and a
dictionary of the command types that it knows how to do/undo.

You can `register` a command, giving it a name and the following
functions:

* `perform(performArgs) -> undoArgs`

* `revert(undoArgs)`

* `update(...) -> performArgs`

The `perform` function is used both to perform the command in
the first place and to redo it.  The `revert` function is used
to undo a command.  The optional `update` function is for
implementing interactive commands (move, resize, etc.) where you
want to modify the arguments of the command that's already in
the history instead of adding a million tiny move commands.

Once you have regsistered your commands, you can use the history
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

Note that we do not forget future commands when you perform a
new one, we simply shift them to an alternate future.  So you
can ask how many futures there are with `futureCount` and choose
one with `chooseFuture`.

* `h:futureCount() -> number`

* `h:chooseFuture(number)`
