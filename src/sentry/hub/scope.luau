--!strict
local Sentry = script.Parent.Parent

local types = require(Sentry.types)
local util = require(Sentry.util)

local scope: types._scope_impl = {} :: types._scope_impl
scope.__index = scope

local defaultScope = {
	extras = {},
	tags = {},

	-- Fill in default useful things
	-- Only typechecking bruh
	level = "error" :: "error",
	logger = types.Event.logger,
	environment = types.Event.environment,

	_eventProcessors = {},
}

function scope.new()
	return setmetatable(util.deepCopy(defaultScope), scope)
end

function scope:clone()
	local newScope = scope.new()

	for key, value in pairs(self) do
		newScope[key] = if type(value) == "table" then util.deepCopy(value) else value
	end

	return newScope
end

function scope:clear()
	for key, _ in pairs(self) do
		if key == '_eventProcessors' then continue end

		local default = defaultScope[key]
		if default then
			self[key] = if typeof(default) == 'table' then util.deepCopy(default) else default
		else
			self[key] = nil
		end
	end
end

function scope:setUser(player)
	if not player then
		self.user = nil
		return
	end
end

function scope:setExtra(key, value)
	self.extras[key] = value
end

function scope:setExtras(extras)
	for key, value in pairs(extras) do
		self.extras[key] = value
	end
end

function scope:setTag(tag, value)
	self.tags[tag] = value
end

function scope:setTags(tags)
	for tag, value in pairs(tags) do
		self.tags[tag] = value
	end
end

function scope:setEnvironment(env)
	self.environment = env
end

function scope:setRelease(release)
	self.release = release
end

function scope:setLogger(logger)
	self.logger = logger
end

function scope:setDist(dist)
	self.dist = dist
end

function scope:setContext(key, context) end

function scope:setFingerprint(fingerprint)
	self.fingerprint = fingerprint
end

local allowedLevels = { "info", "debug", "error", "warning", "fatal" }
function scope:setLevel(level)
	if not table.find(allowedLevels, level) then
		error("Error later")
	end

	-- why can a string not union??
	-- just gotta do this weird cast here
	self.level = level :: "info"
end

function scope:setTransaction(name)
	self.transaction = name
end

function scope:addBreadcrumb(breadcrumb) end

function scope:clearBreadcrumbs()
	self.breadcrumbs = {}
end

function scope:addEventProcessor(processor)
	table.insert(self._eventProcessors, processor)
end

function scope:applyToEvent(event)
	-- Apply scope to event
	for key, value in pairs(self) do
		if key == "_eventProcessors" then
			continue
		end

		event[key] = if type(value) == "table" then util.deepCopy(value) else value
	end

	-- Apply event processors
	for _, processor in ipairs(self._eventProcessors) do
		local success, newEvent = pcall(processor, event)

		if not success then
			warn(`Event processor failed: {newEvent}`)
			return
		end

		-- Drop if no event is returned
		if not newEvent then
			return
		end
		event = newEvent
	end

	return event
end

-- For debugging, will remove later
function scope:__tostring()
	local out = { "Scope" }
	for key, value in pairs(self :: any) do
		table.insert(out, `  {key} = {value}`)
	end

	return table.concat(out, "\n")
end

return scope