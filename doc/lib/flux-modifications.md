# Flux Modifications

* `__call` = `flux.to` - Save three characters, why not.

### `flux.to(obj, time, vars)`
* `vars` can be nil, you don't have to send an empty table.
* If `vars` is a function, it will be used as the `oncomplete` callback.
* Non-number values can be "tweened"--they are simply set to the value
specified in `vars` at the end of the tween.
* All callbacks (`onstart`, `onupdate`, & `oncomplete`) are passed `obj`
and the timer object as arguments.
   * This isn't quite as useful for tweening sub-properties, like: `self.color[4]`, but in those cases you can work around that by storing
	self on the timer object.
   * Timer objects have a `progress` property (0 to 1) which can be useful
   in `onupdate` callbacks.