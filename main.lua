-- Example thingy

require('engine.all')

local Box = require('box')
local flux = require('lib.flux')

function love.load()
	-- init physics world - disable pre- and post-solve callbacks
	world = physics.init(0, 500, true, nil, false, false, true, true)

	local red = { 180, 23, 20 }
	local green = { 30, 200, 25 }

	draw_order = DrawOrder.new('default')
	draw_order:add_layer(1, "bg")

	img_yellow_blob = love.graphics.newImage('yellow-blob.png')
	local img_sq_64 = love.graphics.newImage('square_64.png')
	local img_rect_128x256 = love.graphics.newImage('rect_128x256.png')

	scene = T.new(draw_order, {
		mod(Box.new(300, 200, 30, 30, red), {
			name = 'red-box',
			children = {
				mod(Box.new(20, -25, 8, 8, red), {name = "first red child", angle = math.pi/6}),
				mod(Box.new(20, 25, 18, 4, red), {name = "red arm", angle = math.pi}),
				mod(Box.new(-20, 0, 18, 4, red), {name= "red spinny thing", angle = math.pi, vAngle = -3}),
				mod(Body.new(world, 'kinematic', -20, -10, {{'circle', {25}}}),
					{children = {Sprite.new(img_yellow_blob, 'center', 'center', 10, 0, 0, 0.25)}
				})
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
					script = {
						init = function(self)
							self.t, self.x0, self.y0 = 0, self.pos.x, self.pos.y
						end,
						update = function(self, dt)
							self.t = (self.t + 10*dt) % (2*math.pi)
							self.pos.x = self.x0 - 5*math.sin(self.t)
							self.pos.y = self.y0 + 5*math.cos(self.t)
						end
					}
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
		mod(Body.new(world, 'static', 400, 550, { {'rectangle', {600, 50}} }), {name = "ground"}),
		Camera.new(300, 300, 0, 0.8)
	})

	if scene:get('/red-box') ~= scene.children[1] then
		print('/red-box:', scene:get('/red-box'), scene.children[1])
		error('Getting red box')
	end

	if scene:get('/green-box') ~= scene.children[2] then
		print('/green-box:', scene:get('/green-box'), scene.children[1])
		error('Getting green box')
	end

	physics.set_scene(scene)

	--flux.to(scene.children[1], 2, {sx=2}):oncomplete(function()
	--	flux.to(scene.children[1], 2, {sx=1})
	--end)

	gui_root_obj = Gui_root.new()

	gui_scene = T.new(nil, {
		mod(gui_root_obj, {
			children = {
				mod(Gui_sprite.new(img_rect_128x256, 'right', 'top', -10, 10, 0, 1.5, 1.5, 'right', 'top'), {
					color = {255, 255, 255, 127},
					children = {
						Gui_sprite.new(img_sq_64, 'right', 'center', 0, 0, 0, 0.8, 0.8, 'right', 'bottom')
					}
				}),
				mod(Gui_sprite.new(img_sq_64, 'center', 'bottom', 0, -10, 0, 780/64, 0.5, 'center', 'bottom', 'stretch'), {
					color = {255, 255, 255, 127}
				})
			}
		})
	})
end

function love.resize(w, h)
	Camera.window_resized(w, h)
	gui_root_obj:window_resized(w, h)
end

function love.update(dt)
	flux.update(dt)
	world:update(dt)
	scene:update(dt)
	gui_scene:update(dt)
	Camera.update(dt)
end

function love.draw()
	Camera.apply_transform()
	scene:draw()
	Camera.reset_transform()
	gui_scene:draw()
end

function love.keypressed(k, s)
	if k == 'escape' then
		love.event.quit()
	end
end

function love.mousepressed(x, y, button, isTouch)
	if button == 1 then
		x, y = Camera.screen_to_world(x, y)
		scene:add(mod(Sprite.new(img_yellow_blob, 'center', 'center', x, y), {name='bob'}))
	elseif button == 2 then
		local o
		for k, v in pairs(scene.children) do
			if v then o = v break end
		end
		if o then
			print("removing: ", o.path)
			scene:remove(o)
		else
			print("Object to remove not found")
		end
	end
end
