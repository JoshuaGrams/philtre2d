local base = (...):gsub('[^%.]+$', '')
function love.load(arg)
	require(base .. 'test.all')
	love.event.quit()
end
