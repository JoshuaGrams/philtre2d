
New
===
Available as a global variable, `new`, after requiring `'philtre.init'`.

A tiny helper module for loading assets. The first time you request an asset it is loaded and cached, and thereafter the cached version is returned when the same asset is requested again.

It also caches the parameters used to load an asset, so you can get the filename for an asset or the size of a loaded font.

Functions
---------

### new.image(filename)
Loads an image. See: [love.graphics.newImage](https://love2d.org/wiki/love.graphics.newImage) (the first variant only).

**Returns:** [Image](https://love2d.org/wiki/Image) - Can be used with a Sprite or Quad, or drawn directly.

### new.font(filename, [size], [[hinting](https://love2d.org/wiki/HintingMode)], [dpiscale])
Loads a font. See: [love.graphics.newFont](https://love2d.org/wiki/love.graphics.newFont) (the first two variants, possibly the third?).
- `size` defaults to 12.
- `hinting` defaults to "normal".
- `dpiscale` defaults to [love.graphics.getDPIScale](https://love2d.org/wiki/love.graphics.getDPIScale)().

**Returns:** [Font](https://love2d.org/wiki/Font) - Can be used with a Text object, or to set the current font with [love.graphics.setFont](https://love2d.org/wiki/love.graphics.setFont)

### new.audio(filename, [[sourceType](https://love2d.org/wiki/SourceType)])
Loads a new audio source. See: [love.audio.newSource](https://love2d.org/wiki/love.audio.newSource) (the first variant only).
- `sourceType` defaults to "static".

**Returns:** [Source](https://love2d.org/wiki/Source)

Getting Asset Parameters
------------------------

`new.paramsFor` is a table keyed by assets. To get the parameters for an asset, you simply access it. This gives you a table listing the parameters used to load that asset. For example:
```lua
-- Image
local img = new.image("textures/square_64.png")

-- NOTE: Not calling a function, just accessing a table!
local params = new.paramsFor[img]

-- { "textures/square_64.png" } -- The result.


-- Font
local fnt = new.font("fonts/OpenSans-Regular.ttf", 20)

local params = new.paramsFor[fnt]

-- { "fonts/OpenSans-Regular.ttf", 20 } -- The result.
```

Make sure you do not modify the resulting table, since you are accessing it directly, not using a copy.
