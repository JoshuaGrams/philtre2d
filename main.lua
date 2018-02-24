-- Example thingy

local G = require('engine.scene-graph')
local DrawList = require('engine.draw-order')
local Box = require('box')
local flux = require('lib.flux')

function love.load()
	local red = { 180, 23, 20 }
	local green = { 30, 200, 25 }

	draw_order = DrawList.new('default')
	draw_order:add_layer(-1, "bg")

	local red_box = Box.new(300, 200, 30, 30, red)
	red_box.children = {
		Box.new(20, -25, 8, 8, red),
	}
	red_box.children[1].angle = math.pi/6
	red_box.v.x = 60
	red_box.v.y = 20
	red_box.angular = math.pi
	red_box.sx = 1
	flux.to(red_box, 2, { sx = 2 }):oncomplete(function()
		flux.to(red_box, 2, { sx = 1 })
	end)

	local green_box = Box.new(500, 300, 30, 30, green)
	green_box.children = {
		Box.new(8, -25, 8, 8, green)
	}
	green_box.layer = 'bg'
	green_box.children[1].angle = -math.pi/6

	scene = { red_box, green_box }

	G.init(scene)
end

function love.update(dt)
	flux.update(dt)
	draw_order:clear()
	G.update(scene, dt, draw_order)
end

function love.draw()
	draw_order:draw()
end
