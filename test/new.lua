local base = (...):gsub('[^%.]+%.[^%.]+$', '')
local T = require(base .. 'lib.simple-test')

local new = require(base .. 'core.new')

local loadCalls = 0

local function loader(...)
	loadCalls = loadCalls + 1
	local asset = {}
	for _,k in ipairs({...}) do
		asset[k] = true
	end
	return asset
end

return {
	"New",
	function()
		new.addLoader("testType", loader)
		T.is(type(new.testType), "function", "new.addLoader adds a new function at the appropriate key.")
		T.ok(new.loaded.testType, "new.addLoader adds an asset table for the new type.")
		local isSuccess, result = pcall(new.testType, "one", "two", "three")
		T.ok(isSuccess, "custom loader works without errors.")
		local asset = result
		T.is(type(asset), "table", "Asset is the correct type.")
		T.has(asset, {one=true,two=true,three=true}, "Asset is what we tried to create.")
		local asset2 = new.testType("one", "two", "three")
		T.is(asset2, asset, "Second call to custom loader with the same arguments gives the same asset.")
		T.is(loadCalls, 1, "Second call to custom loader with the same args doesn't call loader again.")
		-- Refcount & unloading.
		T.is(new.refCount[asset], 2, "Refcount of asset is now 2.")
		new.release(asset)
		T.is(new.refCount[asset], 1, "Refcount of asset after releasing one is now 1.")
		new.release(asset)
		T.is(new.refCount[asset], nil, "Refcount of asset is nullified after removing (releasing twice).")
		T.is(new.paramsFor[asset], nil, "ParamsFor asset are nullified after removing.")
		local asset = new.testType("one", "two", "three")
		T.is(loadCalls, 2, "Re-loading custom asset with same args after unloading calls loader again.")
		T.ok(asset ~= asset2, "Re-loading custom asset with same args after unloading gives a different asset.")
		-- Manual unloading.
		local asset3 = new.testType("one", "two", "three")
		local asset4 = new.testType("one", "two", "three")
		local asset5 = new.testType("one", "two", "three")
		T.is(loadCalls, 2, "Loader wasn't called again after loading the same asset a few more times.")
		new.unload(asset)
		T.is(new.refCount[asset], nil, "Refcount of manually unloaded asset is nullified.")
		T.is(new.paramsFor[asset], nil, "ParamsFor manually unloaded asset are nullified.")
		local isSuccess, result = pcall(new.release, asset)
		T.ok(isSuccess, "new.release on already-unloaded asset runs without errors.")
	end
}
