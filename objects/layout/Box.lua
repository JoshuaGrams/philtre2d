local base = (...):gsub('objects%.layout%.Box$', '')
local Object = require(base .. 'objects.Object')

local Box = Object:extend()

Box.className = 'Layout.Box'

function Box.set(b, w, h)
	Object.set(b)
	b._req = { w = w, h = h }
end

function Box.draw() end

function Box.request(b)  return b._req  end

function Box.allocate(b, x, y, w, h)
	b.pos.x, b.pos.y, b.width, b.height = x, y, w, h
	if b.children then
		for i,v in ipairs(b.children) do
			if v.allocate then  v:allocate(x, y, w, h)  end
		end
	end
end

return Box
