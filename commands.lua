local Class = require 'philtre.lib.base-class'

local Commands = Class:extend()

function Commands.set(self, commands)
	self.commands = commands
	self.past, self.future = {}, {}
end

function Commands.clear(self)
	self.past, self.future = {}, {}
end

local function saveAlternateFuture(self)
	local top = self.past[#self.past]
	if top and #self.future > 0 then
		if not top.futures then top.futures = {} end
		table.insert(top.futures, self.future)
		self.future = {}
	end
end

local function inList(x, list)
	for i,v in ipairs(list) do
		if x == v then return i end
	end
	return false
end

function Commands.otherFutures(self)
	local top = self.past[#self.past]
	return top and top.futures
end

function Commands.chooseFuture(self, n)
	local top = self.past[#self.past]
	local hasFuture = top and top.futures and top.futures[n]
	if hasFuture then
		if not inList(self.future, top.futures) then
			saveAlternateFuture(self)
		end
		self.future = top.futures[index]
	end
	return hasFuture
end

function Commands.perform(self, name, ...)
	local perform = self.commands[name][1]
	local undoArgs = { perform(...) }
	saveAlternateFuture(self)
	table.insert(self.past, {name, {...}, undoArgs})
end

-- Modify the saved arguments for the most recent command.
function Commands.update(self, ...)
	local top = self.past[#self.past]
	if top then top[2] = {...} end
	return top ~= nil
end

function Commands.undo(self)
	local command = table.remove(self.past)
	if command then
		local name, _, undoArgs = unpack(command)
		local undo = self.commands[name][2]
		undo(unpack(undoArgs))
		table.insert(self.future, command)
	end
	return command ~= nil
end

function Commands.redo(self, future)
	local command = table.remove(self.future)
	if command then
		local name, args = unpack(command)
		local perform = self.commands[name][1]
		perform(unpack(args))
		table.insert(self.past, command)
	end
	return command ~= nil
end

return Commands
