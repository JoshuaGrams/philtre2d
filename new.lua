local new = {
	root = '',
	loaded = { image = {}, font = {}, audio = {} }
}

local function create(kind, fn, filename, ...)
	local existing = new.loaded[kind]
	local keys = {filename, ...}
	for i=1,#keys-1 do
		local key = keys[i]
		if not existing[key] then existing[key] = {} end
		existing = existing[key]
	end
	local key = keys[#keys]
	if not existing[key] then
		existing[key] = fn(new.root .. filename, ...)
	end
	return existing[key]
end

function new.image(filename)
	return create('image', love.graphics.newImage, filename)
end

function new.font(filename, size)
	return create('font', love.graphics.newFont, filename, size)
end

function new.audio(filename)
	return create('audio', love.graphics.newSource, filename)
end

return new
