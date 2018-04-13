-- Example thingy

require('engine.all')
assets = require('lib.cargo').init('assets')

function love.load()
	gui_scene = T.new(nil, {
		mod(Gui_root.new(), {
			children = {
				mod(Gui_sprite.new(assets.tex.rect_128x256, 'right', 'top', -10, 10, 0, 1.5, 1.5, 'right', 'top'), {
					color = {255, 255, 255, 127},
					children = {
						Gui_sprite.new(assets.tex.square_64, 'right', 'center', 0, 0, 0, 0.8, 0.8, 'right', 'bottom'),
						Gui_text.new(0, 10, 0, 'Gui Text Object', 'assets/fonts/OpenSans-Regular.ttf', 16, 300, 'center', 1/1.5, 1/1.5, 'center', 'top')
					}
				}),
				mod(Gui_sprite.new(assets.tex.square_64, 'center', 'bottom', 0, -10, 0, 780/64, 0.5, 'center', 'bottom', 'stretch'), {
					color = {255, 255, 255, 127}
				}),
				Gui_text.new(0, 20, 0, 'Gui Text Object', 'assets/fonts/OpenSans-Regular.ttf', 32, 300, 'center', 1/1.5, 1/1.5, 'center', 'center', 'zoom'),
				Gui_text.new(0, 0, 0, 'Gui Text Object', 'assets/fonts/OpenSans-Regular.ttf', 32, 300, 'center', 1/1.5, 1/1.5, 'center', 'center', 'zoom'),
				Gui_text.new(0, -20, 0, 'Gui Text Object', 'assets/fonts/OpenSans-Regular.ttf', 32, 300, 'center', 1/1.5, 1/1.5, 'center', 'center', 'zoom'),
				mod(Gui_sprite.new(assets.tex.square_64, 'center', 'center', -200, 70, 0, 1, 1, 'center', 'center', 'fit'), {
					color = {255, 255, 255, 127}
				}),
				mod(Gui_sprite.new(assets.tex.square_64, 'center', 'center', -200, 0, 0, 1, 1, 'center', 'center', 'fit'), {
					color = {255, 255, 255, 127}
				}),
				mod(Gui_sprite.new(assets.tex.square_64, 'center', 'center', -200, -70, 0, 1, 1, 'center', 'center', 'fit'), {
					color = {255, 255, 255, 127}
				}),
			}
		})
	})
end

function love.resize(w, h)
	Gui_root.window_resized(w, h)
end

function love.update(dt)
	gui_scene:update(dt)
end

function love.draw()
	gui_scene:draw()
end

function love.keypressed(k, s)
	if k == 'escape' then
		love.event.quit()
	end
end
