--!strict
local HttpService = game:GetService("HttpService")
local Sentry = script.Parent

local _scope = require(script.scope)
local types = require(Sentry.types)
local util = require(Sentry.util)
local log = require(Sentry.log)

local hub: types._hub_impl = {} :: types._hub_impl
hub.__index = hub

function hub.new(transport, scope, sampleRate)
	return setmetatable({
		transport = transport,
		sampleRate = sampleRate or 1,
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
	event.timestamp = DateTime.now().UnixTimestamp

	local new = scope:applyToEvent(event)
	if not event then return end

	event = new :: types.Event

	for key, value in pairs(event) do
		if typeof(value) ~= 'table' then continue end

		local kept = util.removeIfEmpty(value)
		event[key] = kept
	end

	local success, json = pcall(HttpService.JSONEncode, HttpService, event)
	if not success then
		log.log(2, `Failed to encode event payload: {json}`)
		return
	end

	local transportSuccess, response = self.transport:sendEvent(json)
	if transportSuccess then
		self._lastEventId = response
	end

	return if transportSuccess then response else nil
end

-- TODO: Finish implementation further
function hub:captureException(exception)
	local newEvent = util.deepCopy(types.Event)
	newEvent.exception = {
		type = "Error",
		value = exception
	}

	return self:captureEvent(newEvent, self.stack[#self.stack])
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