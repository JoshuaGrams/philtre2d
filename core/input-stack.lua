
local function pushDelayed(stack, cbName, object, arg)
	-- We'll iterate through them backwards, so insert on bottom to keep correct order.
	table.insert(stack.delayed, 1, {cbName, object, arg})
	stack.isDirty = true
end

local function doDelayed(stack)
	for i=#stack.delayed,1,-1 do
		local params = stack.delayed[i]
		local cbName, obj, arg = params[1], params[2], params[3]
		stack[cbName](stack, obj, arg)
		stack.delayed[i] = nil
	end
end

local function add(stack, object, index)
	if stack.isLocked then
		pushDelayed(stack, "add", object, index)
	else
		if index then
			if index > 0 then  index = math.min(index, #stack+1) -- Positive values are indices.
			else  index = math.max(1, #stack+1 + index)  end -- 0 or Negative values are offsets from top.
		else
			index = #stack + 1
		end
		table.insert(stack, index, object)
	end
end

local function remove(stack, object)
	if stack.isLocked then
		pushDelayed(stack, "remove", object)
	else
		for i=#stack,1,-1 do
			if stack[i] == object then
				table.remove(stack, i)
			end
		end
	end
end

local function _sendInput(stack, ...)
	local callback = stack.callback
	for i=#stack,1,-1 do
		local obj = stack[i]
		local r
		if obj[callback] then  r = obj[callback](obj, ...)  end
		if r then  return r  end
		if obj.scripts then
			for _,script in ipairs(obj.scripts) do
				if script[callback] then  r = script[callback](obj, ...)  end
				if r then  return r  end
			end
		end
	end
end

local function call(stack, ...)
	stack.isLocked = true
	local r = _sendInput(stack, ...)
	stack.isLocked = false
	if stack.isDirty then
		doDelayed(stack)
		stack.isDirty = false
	end
	return r
end

local function InputStack(callback)
	return {
		add = add,
		remove = remove,
		call = call,
		callback = callback or "input",
		isLocked = false,
		isDirty = false,
		delayed = {}
	}
end

return InputStack
