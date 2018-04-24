-- Load engine components into global variables

matrix = require 'engine.matrix'

scene = require 'engine.scene-tree'
DrawOrder = require 'engine.draw-order'

Input = require 'engine.input'
physics = require 'engine.physics'

-- Objects
Object = require 'engine.Object'
Sprite = require 'engine.Sprite'
Body = require 'engine.Body'
World = require 'engine.World'
Camera = require 'engine.Camera'
GuiRoot = require 'engine.gui_root'
GuiSprite = require 'engine.gui_sprite'
GuiText = require 'engine.gui_text'
Text = require 'engine.text'

-- Note that `props` override values already on `obj`.  This is
-- deliberate, so we can insert a file into a bigger scene and
-- then customize it.
function mod(obj, props)
	for name,prop in pairs(props) do
		obj[name] = prop
	end
	return obj
end
