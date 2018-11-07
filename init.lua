-- Load engine components into global variables

local base = (...):gsub('%.init$', '.')

matrix = require(base .. 'matrix')

scene = require(base .. 'scene-tree')
DrawOrder = require(base .. 'draw-order')

Input = require(base .. 'input')
physics = require(base .. 'physics')

-- Objects
Object = require(base .. 'Object')
Sprite = require(base .. 'Sprite')
Quad = require(base .. 'Quad')
Body = require(base .. 'Body')
World = require(base .. 'World')
Camera = require(base .. 'Camera')
Text = require(base .. 'Text')

-- Note that `props` override values already on `obj`.  This is
-- deliberate, so we can insert a file into a bigger scene and
-- then customize it.
function mod(obj, props)
	for name,prop in pairs(props) do
		obj[name] = prop
	end
	return obj
end
