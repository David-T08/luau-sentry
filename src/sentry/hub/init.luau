--!strict
local HttpService = game:GetService("HttpService")
local Sentry = script.Parent

local types = require(Sentry.types)
local _scope = require(script.scope)
local util = require(Sentry.util)

local hub: types._hub_impl = {} :: types._hub_impl
hub.__index = hub

function hub.new(transport, scope, sampleRate)
	return setmetatable({
		transport = transport,
		sampleRate = sampleRate or 0.5,
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

function hub:captureEvent(event, scope)
	if self.sampleRate == 0 then return end
	if math.random() > self.sampleRate then return end

	event.event_id = HttpService:GenerateGUID(false):gsub("-", "")
	event.timestamp = DateTime.now().UnixTimestampMillis

	event = scope:applyToEvent(event)
	if not event then return end

	local success, json = pcall(HttpService.JSONEncode, HttpService, event)
	if not success then
		warn(`Failed to encode event payload: {json}`)
		return
	end

	-- self.transport
end

function hub:captureException(exception)
	return 'not-implemented'
end

function hub:captureMessage(message)
	local newEvent = util.deepCopy(types.Event)
	newEvent.message = {
		formatted = message
	}

	return self:captureEvent({
		message = {
			formatted = message
		}
	} :: any, self.stack[#self.stack])
end

local function threadId()
	local str = tostring(coroutine.running())
	return str:sub(8, #str)
end

function hub:__tostring()
	return `Hub {threadId()}`
end

return hub