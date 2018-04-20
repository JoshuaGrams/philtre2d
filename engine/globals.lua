-- Load engine components into global variables

M = require('engine.matrix')

scene = require('engine.scene-tree');

DrawOrder = require('engine.draw-order')
physics = require('engine.physics')
Sprite = require('engine.sprite')
Body = require('engine.body')
Camera = require('engine.lovercam')
GuiRoot = require('engine.gui_root')
GuiSprite = require('engine.gui_sprite')
GuiText = require('engine.gui_text')
Input = require('engine.input')
Text = require('engine.text')

-- Note that `props` override values already on `obj`.  This is
-- deliberate, so we can insert a file into a bigger scene and
-- then customize it.
function mod(obj, props)
	for name,prop in pairs(props) do
		obj[name] = prop
	end
	return obj
end
