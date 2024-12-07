--!strict

local Sentry = script.Parent

local types = require(Sentry.types)
local _scope = require(script.scope)

local hub: types._hub_impl = {} :: types._hub_impl
hub.__index = hub

function hub.new(transport, scope)
	return setmetatable({
		transport = transport,
		stack = {scope or _scope.new()}
	}, hub)
end

function hub:clone()
	local stack = self.stack
	return hub.new(self.transport, stack[#stack]:clone())
end

function hub:pushScope()
	local stack = self.stack
	local newScope = stack[#stack]:clone()

	table.insert(stack, newScope)

	-- Return a function to safely pop this scope
	return function() 
		table.remove(stack)
	end
end

function hub:captureEvent(event)
	return 'not-implemented'
end

function hub:captureException(exception)
	return 'not-implemented'
end

function hub:captureMessage(message)
	return 'not-implemented'
end

local function threadId()
	local str = tostring(coroutine.running())
	return str:sub(8, #str)
end

function hub:__tostring()
	return `Hub {threadId()}`
end

return hub