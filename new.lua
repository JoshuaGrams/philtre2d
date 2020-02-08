local new = {
	rootPath = '',
	loaded = { image = {}, font = {}, audio = {} },
	paramsFor = {} -- Keys: loaded assets, Values: The original parameters used to load them.
}

local function create(assetType, fn, filename, ...)
	local existing = new.loaded[assetType]
	local keys = {filename, ...}
	for i=1,#keys-1 do
		local key = keys[i]
		if not existing[key] then existing[key] = {} end
		existing = existing[key]
	end
	local finalKey = keys[#keys]
	if not existing[finalKey] then
		local asset = fn(new.rootPath .. filename, ...)
		existing[finalKey] = asset
		new.paramsFor[asset] = keys
	end
	return existing[finalKey]
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
