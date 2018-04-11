-- Manage a command history with undo, redo, etc.

-- local references to library functions
local append = table.insert
local removeLast = table.remove

local function appendAll(seq, ...)
	for i=1,select('#', ...) do
		append(seq, select(i, ...))
	end
end

local function selector(self, fn)
	self.selectors[fn] = fn
end

local function expand(self, args)
	if type(args) ~= 'table' then return args end
	local out = {}
	for i,arg in ipairs(args) do
		if type(arg) == 'table' and self.selectors[arg[1]] then
			local fn, fnArgs = arg[1], {unpack(arg, 2)}
			appendAll(out, fn(expand(self, fnArgs)))
		else
			append(out, arg)
		end
	end
	return unpack(out)
end

local function command(self, name, perform, revert, update)
	self.commands[name] = {
		perform = perform,
		revert = revert,
		update = update
	}
end

local function commandInstance(self, fns, name, args)
	return {
		future = {},
		perform = fns.perform,  revert = fns.revert,
		update = fns.update,
		name = name,  args = {unpack(args)},
		undoArgs = { fns.perform(expand(self, args)) }
	}
end

local function perform(self, name, ...)
	local fns = self.commands[name]
	local cmd = commandInstance(self, fns, name, {...})
	local prev = self.mostRecent
	cmd.past = prev
	append(prev.future, 1, cmd)
	self.mostRecent = cmd
	-- Return undoArgs for interactive commands, e.g. when
	-- interactively creating an object you may want to move or
	-- resize it immediately.
	return cmd.undoArgs
end

local function undo(self)
	local cmd = self.mostRecent
	cmd.revert(expand(self, cmd.undoArgs))
	self.mostRecent = cmd.past
end

local function redo(self)
	local cmd = self.mostRecent.future[1]
	if cmd then
		cmd.undoArgs = { cmd.perform(expand(self, cmd.args)) }
		self.mostRecent = cmd
	end
end

local function update(self, ...)
	local cmd = self.mostRecent
	if cmd.update then
		cmd.args = {cmd.update(...)}
	else
		-- TODO - this is wrong: perform takes a name.
		-- Should we give an error?  Or...?
		cmd.args = {...}
		cmd.perform(...)
	end
end

local function cancel(self)
	local cmd = self.mostRecent
	if cmd.past ~= cmd then
		cmd.revert(expand(self, cmd.undoArgs))
		for _,v in ipairs(cmd.future) do
			append(cmd.past.future, v)
		end
		local futures = cmd.past.future
		for i=1,#futures do
			if futures[i] == cmd then
				removeLast(futures, i)
				break
			end
		end
		self.mostRecent = cmd.past
	end
end

local function chooseFuture(self, n)
	local f = self.mostRecent.future
	if n <= #f and n >= 1 then
		append(f, 1, removeLast(f, n))
	end
end

local function futureCount(self)
	return #self.mostRecent.future
end

local methods = {
	command = command,  selector = selector,
	perform = perform,  undo = undo,  redo = redo,
	update = update,  cancel = cancel,
	chooseFuture = chooseFuture,  futureCount = futureCount
}
local class = { __index = methods }

local function noop() end

local function new()
	local h = { commands = {}, selectors = {} }
	-- Ensure that there's always a dummy command in the history
	-- to make the code simpler.
	local noops = { perform = noop,  revert = noop }
	h.mostRecent = commandInstance(h, noops, nil, {})
	h.mostRecent.past = h.mostRecent
	return setmetatable(h, class)
end

return { new = new, methods = methods, class = class }
