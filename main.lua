-- Example thingy

require('engine.all')

local Box = require('box')
local Body = require('engine.body')
local flux = require('lib.flux')

function love.load()
	world = love.physics.newWorld(0, 500, true)

	--local ball = Body.new(world, 'dynamic', 300, 300, 'circle', 50)

	local red = { 180, 23, 20 }
	local green = { 30, 200, 25 }

	draw_order = DrawOrder.new('default')
	draw_order:add_layer(1, "bg")

	local img_yellow_blob = love.graphics.newImage('yellow-blob.png')

	scene = T.new(draw_order, {
		mod(Box.new(300, 200, 30, 30, red), {
			name = 'red-box',
			children = {
				mod(Box.new(20, -25, 8, 8, red), {name = "first red child", angle = math.pi/6}),
				mod(Box.new(20, 25, 18, 4, red), {name = "red arm", angle = math.pi}),
				mod(Box.new(-20, 0, 18, 4, red), {name= "red spinny thing", angle = math.pi, vAngle = -3})
			},
			v = { x = 60, y = 20 },
			vAngle = math.pi,
			sx = 1
		}),
		mod(Box.new(250, 100, 30, 30, green), {
			angle = 0.5,
			name = 'green-box',
			layer = 'bg',
			children = {
				mod(Box.new(8, -25, 8, 8, green), {
					angle=-math.pi/6,
				}),
			}
		}),
		mod(Sprite.new(img_yellow_blob, 'center', 'center', 100, 100), {
			update = function(self, dt)
				self.angle = self.angle - dt * 4*math.pi
			end
		}),
		mod(Body.new(world, 'dynamic', 400, 100, { {'circle', {50}, restitution = 0.2}, { 'circle', {-34, 0, 20}}}, {gScale=5}), {
			name = 'physics body',
			children = {
				mod(Sprite.new(img_yellow_blob, 'center', 'center', 15, 0, math.pi/6), {name='physics body child'})
			},
		}),
		Body.new(world, 'static', 400, 550, { {'rectangle', {600, 50}} })
	})

	if scene:get('/red-box') ~= scene.children[1] then
		print('/red-box:', scene:get('/red-box'), scene.children[1])
		error('Getting red box')
	end

	if scene:get('/green-box') ~= scene.children[2] then
		print('/green-box:', scene:get('/green-box'), scene.children[1])
		error('Getting green box')
	end

	flux.to(scene.children[1], 2, {sx=2}):oncomplete(function()
		flux.to(scene.children[1], 2, {sx=1})
	end)
end

function love.update(dt)
	flux.update(dt)
	world:update(dt)
	scene:update(dt)
end

function love.draw()
	scene:draw()
end

function love.keypressed(k, s)
	if k == 'escape' then
		love.event.quit()
	end
end
