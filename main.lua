local G = require('scene-graph')
local DrawList = require('draw-order')
local Box = require('box')
local flux = require('flux')

function love.load()
	local red = { 180, 23, 20 }
	local green = { 30, 200, 25 }

	draw_order = DrawList.new('default')

	scene = {
		Box.new(300, 200, 30, 30, red),
		Box.new(120, 300, 30, 30, green)
	}

	scene[1].v.x = 60
	scene[1].v.y = 20
	scene[1].angular = math.pi
	scene[1].sx = 1
	flux.to(scene[1], 2, { sx = 2 }):oncomplete(function()
		flux.to(scene[1], 2, { sx = 1 })
	end)

	scene[1].children = {
		Box.new(20, -25, 8, 8, red),
	}
	scene[1].children[1].angle = math.pi/6
	scene[2].children = {
		Box.new(8, -25, 8, 8, green)
	}
	scene[2].children[1].angle = -math.pi/6

	G.init(scene)
end

function love.update(dt)
	flux.update(dt)
	draw_order:reset()
	G.update(scene, dt, draw_order)
end

function love.draw()
	draw_order:draw()
end
