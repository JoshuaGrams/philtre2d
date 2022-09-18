local new = {
	loaded = { image = {}, quad = {}, font = {}, audio = {} },
	paramsFor = {} -- Keys: loaded assets, Values: The original parameters used to load them.
}

local function create(assetType, fn, ...)
	local existing = new.loaded[assetType]
	local keys = {...}
	for i=1,#keys-1 do
		local key = keys[i]
		if not existing[key] then existing[key] = {} end
		existing = existing[key]
	end
	local finalKey = keys[#keys]
	if not existing[finalKey] then
		local asset = fn(...)
		existing[finalKey] = asset
		new.paramsFor[asset] = keys
	end
	return existing[finalKey]
end

function new.custom(assetType, loaderFn, ...)
	new.loaded[assetType] = new.loaded[assetType] or {}
	return create(assetType, loaderFn, ...)
end

function new.image(filename)
	return create('image', love.graphics.newImage, filename)
end

function new.quad(x, y, width, height, iw, ih)
	return create('quad', love.graphics.newQuad, x, y, width, height, iw, ih)
end

function new.font(filename, size, ...)
	return create('font', love.graphics.newFont, filename, size or 12, ...)
end

function new.audio(filename, sourceType)
	return create('audio', love.audio.newSource, filename, sourceType or "static")
end

return new
