
-- Constructs objects that manage an input stack with consumable input calls.

function add(self, obj, pos)
	pos = pos or "top"
	if self.isCalling then
		return table.insert(self.delayedAddRemoves, {"add", obj, pos})
	end
	if pos == "top" then
		table.insert(self.stack, 1, obj) -- First on stack is the "top" - the first to get input.
	else -- Add to bottom.
		table.insert(self.stack, obj)
	end
end

function remove(self, obj)
	if self.isCalling then
		-- `Delayed` list is in reverse order so it will be correct when
		--  iterating through it backwards.
		return table.insert(self.delayedAddRemoves, 1, {"remove", obj})
	end
	for i,v in ipairs(self.stack) do
		if v == obj then
			return table.remove(self.stack, i)
		end
	end
end

function doDelayedCalls(self)
	for i=#self.delayedAddRemoves,1,-1 do
		local v = self.delayedAddRemoves[i]
		if v[1] == "add" then
			self:add(v[2], v[3])
		else
			self:remove(v[2])
		end
		self.delayedAddRemoves[i] = nil
	end
end

-- Calls the named function on an object and its scripts, stopping on the first truthy return value.
local function consumableCall(obj, funcName, ...)
	local r
	if obj[funcName] then
		r = obj[funcName](obj, ...)
		if r then  return r  end
	end
	if obj.script then
		for i=1,#obj.script do
			local scr = obj.script[i]
			if scr[funcName] then
				r = scr[funcName](obj, ...)
				if r then  return r  end
			end
		end
	end
end

local function call(self, ...)
	-- Can cause infinite loops and other wacky behavior if you modify the stack while
	-- iterating through it, so delay all add-removes until the input is dealt with.
	self.isCalling = true
	local r -- return value
	for i=1,#self.stack do
		local obj = self.stack[i]
		r = consumableCall(obj, "input", ...)
		if r then  break  end
	end
	self.isCalling = false
	doDelayedCalls(self)
	return r
end

local function new()
	local self = {
		stack = {},
		add = add,
		remove = remove,
		call = call,
		isCalling = false,
		delayedAddRemoves = {}
	}
	return self
end

return new
