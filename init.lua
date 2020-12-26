-- Load engine components into global variables

local base = (...):gsub('%.init$', '.')

matrix = require(base .. 'modules.matrix')
new = require(base .. 'modules.new')

SceneTree = require(base .. 'objects.SceneTree')
DrawOrder = require(base .. 'render.draw-order')

Input = require(base .. 'modules.input')
physics = require(base .. 'modules.physics')

-- Objects
Object = require(base .. 'objects.Object')
Sprite = require(base .. 'objects.Sprite')
Quad = require(base .. 'objects.Quad')
Body = require(base .. 'objects.Body')
World = require(base .. 'objects.World')
Camera = require(base .. 'objects.Camera')
Text = require(base .. 'objects.Text')

-- Note that `props` override values already on `obj`.  This is
-- deliberate, so we can insert a file into a bigger scene and
-- then customize it.
function mod(obj, props)
	for name,prop in pairs(props) do
		obj[name] = prop
	end
	return obj
end
