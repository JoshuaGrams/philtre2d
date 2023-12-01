local new = {
	loaded = { image = {}, quad = {}, font = {}, audio = {} },
	paramsFor = {}, -- Keys: loaded assets, Values: The original parameters used to load them.
	refCount = {}
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
		keys.assetType = assetType
		new.paramsFor[asset] = keys
	end
	local asset = existing[finalKey]
	new.refCount[asset] = (new.refCount[asset] or 0) + 1
	return asset
end

function new.unload(asset)
	local keys = new.paramsFor[asset]
	local keyCount = #keys
	local existing = new.loaded[keys.assetType]
	for i=1,keyCount-1 do
		existing = existing[keys[i]]
	end
	existing[keys[keyCount]] = nil
	new.paramsFor[asset] = nil
	new.refCount[asset] = nil
end

function new.release(asset)
	local refCount = new.refCount[asset]
	if refCount then
		refCount = refCount - 1
		if refCount <= 0 then
			new.unload(asset)
		else
			new.refCount[asset] = refCount
		end
	end
end

function new.addLoader(assetType, loaderFn)
	new.loaded[assetType] = new.loaded[assetType] or {}
	new[assetType] = function(...)  return create(assetType, loaderFn, ...)  end
end

function new.image(filename)
	return create('image', love.graphics.newImage, filename)
end

function new.quad(x, y, width, height, iw, ih)
	return create('quad', love.graphics.newQuad, x, y, width, height, iw, ih)
end

function new.font(...) -- Usually: new.font(filename, size)
	return create('font', love.graphics.newFont, ...)
end

function new.audio(filename, sourceType)
	return create('audio', love.audio.newSource, filename, sourceType or "static")
end

return new
