--!strict
local transporter = require(script.transporter)
local hub = require(script.hub)
local types = require(script.types)

local clients: {[string]: types.Sentry} = {}

local sentrySDK: types._sentry_impl = {} :: types._sentry_impl
sentrySDK.__index = sentrySDK

local function threadId()
	local str = tostring(coroutine.running())
	return str:sub(8, #str)
end

function sentrySDK.init(options, name)
	assert(name, `Sentry client name is required!`)
	assert(clients[name] == (nil :: any), `Sentry client '{name}' already exists!`)

	local transport = transporter.init(options)

	local mainHub = hub.new(transport)
	local newSentry = {
		_main_hub = mainHub,
		_hubs = {
			[threadId()] = mainHub
		},

		transport = transport
	}

	setmetatable(newSentry, sentrySDK)
	clients[name] = newSentry

	return newSentry
end

-- Every script will have to do SentrySDK.get("whatever")
-- We do this because you may want multiple Sentry clients
function sentrySDK.get(name)
	local client = clients[name]
	assert(client, `Sentry client '{name}' not found!`)

	return clients[name]
end

function sentrySDK:globalHub()
	return self._main_hub
end

function sentrySDK:currentHub()
	local id = threadId()
	local found = self._hubs[id]

	if not found then
		local cloned = self._main_hub:clone()

		found = cloned
		self._hubs[id] = cloned
	end

	return found
end

function sentrySDK:transport()	
	return self.transport
end

function sentrySDK:captureMessage(message)
	return self:currentHub():captureMessage(message)
end	

function sentrySDK:captureEvent(event)
	return self:currentHub():captureEvent(event)
end

function sentrySDK:captureException(exception)
	return self:currentHub():captureException(exception)
end

function sentrySDK:lastEventId()
	return self:currentHub()._lastEventId
end

function sentrySDK:configureScope(callback)
	local hub = self:currentHub()
	local stack = hub.stack

	callback(stack[#stack])
end

-- TODO 
-- Resource: https://develop.sentry.dev/sdk/miscellaneous/unified-api
-- start_session()
-- end_session()


return {
	init = sentrySDK.init,

	transporter = transporter
}