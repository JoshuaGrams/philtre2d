-- Manage a command history with undo, redo, etc.

local function register(history, name, perform, revert, update)
	history.functions[name] = {
		perform = perform,
		revert = revert,
		update = update
	}
end

local function newCmd(fns, name, args)
	return {
		future = {},
		perform = fns.perform,  revert = fns.revert,
		update = fns.update,
		name = name,  args = args,
		undoArgs = { fns.perform(unpack(args)) }
	}
end

local function perform(history, name, ...)
	local fns = history.functions[name]
	local cmd = newCmd(fns, name, {...})
	local prev = history.mostRecent
	cmd.past = prev
	table.insert(prev.future, 1, cmd)
	history.mostRecent = cmd
	-- Return undoArgs for interactive commands, e.g. when
	-- interactively creating an object you may want to move or
	-- resize it immediately.
	return cmd.undoArgs
end

local function undo(history)
	local cmd = history.mostRecent
	cmd.revert(unpack(cmd.undoArgs))
	history.mostRecent = cmd.past
end

local function redo(history)
	local cmd = history.mostRecent.future[1]
	if cmd then
		cmd.undoArgs = { cmd.perform(unpack(cmd.args)) }
		history.mostRecent = cmd
	end
end

local function update(history, ...)
	local cmd = history.mostRecent
	if cmd.update then
		cmd.args = cmd.update(...)
	else
		cmd.args = {...}
		cmd.perform(...)
	end
end

local function cancel(history)
	local cmd = history.mostRecent
	if cmd.past ~= cmd then
		cmd.revert(unpack(cmd.undoArgs))
		for _,v in ipairs(cmd.future) do
			table.insert(cmd.past.future, v)
		end
		local futures = cmd.past.future
		for i=1,#futures do
			if futures[i] == cmd then
				table.remove(futures, i)
				break
			end
		end
		history.mostRecent = cmd.past
	end
end

local function chooseFuture(history, n)
	local f = history.mostRecent.future
	if n <= #f and n >= 1 then
		table.insert(f, 1, table.remove(f, n))
	end
end

local function futureCount(history)
	return #history.mostRecent.future
end

local methods = {
	register = register,
	perform = perform,  undo = undo,  redo = redo,
	update = update,  cancel = cancel,
	chooseFuture = chooseFuture,  futureCount = futureCount
}
local class = { __index = methods }

local function noop() end

local function new()
	local noops = { perform = noop,  revert = noop }
	local h = {
		functions = {},
		mostRecent = newCmd(noops, nil, {})
	}
	h.mostRecent.past = h.mostRecent
	return setmetatable(h, class)
end

return { new = new, methods = methods, class = class }
