A Simple Test Runner
====================

Run tests with `T.check(item)`, where `item` is one of:

* Function - gets run, performs some checks.

* String - message, gets sent as part of the output.

* Table `{ item1, item2, ... }` - group of tests.  Can have
  optional `setup` and `teardown` functions which provide and
  destroy a context object which will be passed to each test
  function.


`T.plan()` must be called exactly once.  You usually do this
after you are done testing, but if you know exactly how many
checks should be run, you can call `T.plan(nTests)` before you
start testing.

-----

There are currently three methods which perform checks.

* `T.ok(flag, message)` - Checks that the flag is truthy.

* `T.is(a, b, message)` - Checks that `a == b`.

* `T.has(t1, t2, message, [tableName])` - Checks that `t1` has
  properties matching those in `t2`.

Failed tests are normally not fatal.  If you need a test to be
fatal, call `T.bail(msg)` when a check returns `false` (or if
you need to exit early for some other reason).

You can also send progress reports from your test functions with
`T.note(message)`.
