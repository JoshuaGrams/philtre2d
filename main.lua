-- Example thingy

require('engine.all')

local Box = require('box')
local flux = require('lib.flux')

function love.load()
	local red = { 180, 23, 20 }
	local green = { 30, 200, 25 }

	draw_order = DrawOrder.new('default')
	draw_order:add_layer(1, "bg")

	scene = T.new(draw_order, {
		mod(Box.new(300, 200, 30, 30, red), {
			name = 'red-box',
			children = {
				mod(Box.new(20, -25, 8, 8, red), {angle = math.pi/6})
			},
			v = { x = 60, y = 20 },
			vAngle = math.pi,
			sx = 1
		}),
		mod(Box.new(500, 300, 30, 30, green), {
			name = 'green-box',
			layer = 'bg',
			children = {
				mod(Box.new(8, -25, 8, 8, green), {angle=-math.pi/6})
			}
		}),
		mod(Sprite.new('yellow-blob.png', 'center', 'center', 100, 100), {
			update = function(self, dt)
				self.angle = self.angle - dt * 4*math.pi
			end
		})
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
