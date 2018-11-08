-- Copyright (C) 2018 Joshua Grams <josh@qualdan.com>
--
-- This module is free software; you can redistribute it and/or
-- modify it under the terms of the MIT license.

local none = {}

local include = {
	replace = function(obj, k, v)
		return true
	end,

	skip = function(obj, k, v)
		return obj[k] == nil
	end,

	error = function(obj, k, v)
		if obj[k] ~= nil then
			error("Class already has a " .. k .. " property.")
		else
			return true
		end
	end
}

local exclude = { __index = true, super = true }

local function implements(class, interface, policy)
	local ok = policy
	if type(policy) ~= 'function' then
		ok = include[policy or 'replace']
	end
	for k,v in pairs(interface or none) do
		if not exclude[k] and ok(class, k, v) then
			class[k] = v
		end
	end
end

local function extend(parent, policy)
	local class = {}
	implements(class, parent, policy)
	-- Use the same table for metamethods and normal methods.
	class.__index = class
	class.super = parent
	setmetatable(class, parent)
	return class
end

local function is(obj, class)
	repeat
		obj = getmetatable(obj)
		if obj == class then return true end
	until not obj
	return false
end

local function new(class, ...)
	local obj = {}
	obj.id = tostring(obj):sub(1 + ("table: "):len())
	setmetatable(obj, class)
	obj:set(...)
	return obj
end

local Class = extend()
Class.implements = implements
Class.extend = extend
Class.is = is
Class.new, Class.__call = new, new

Class.set = function() end
Class.__tostring = function(self)
	return "Object: " .. self.id
end

return Class
