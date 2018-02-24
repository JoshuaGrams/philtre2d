-- Example thingy

local G = require('engine.scene-graph')
local mod = G.mod
local DrawList = require('engine.draw-order')
local Box = require('box')
local flux = require('lib.flux')

function love.load()
	local red = { 180, 23, 20 }
	local green = { 30, 200, 25 }

	draw_order = DrawList.new('default')
	draw_order:add_layer(1, "bg")

	scene = {
		mod(Box.new(300, 200, 30, 30, red), {
			children = {
				mod(Box.new(20, -25, 8, 8, red), {angle = math.pi/6})
			},
			v = { x = 60, y = 20 },
			angular = math.pi,
			sx = 1
		}),
		mod(Box.new(500, 300, 30, 30, green), {
			layer = 'bg',
			children = {
				mod(Box.new(8, -25, 8, 8, green), {angle=-math.pi/6})
			}
		})
	}
	flux.to(scene[1], 2, {sx=2}):oncomplete(function()
		flux.to(scene[1], 2, {sx=1})
	end)

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
