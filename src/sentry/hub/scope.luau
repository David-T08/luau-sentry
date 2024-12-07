--!strict
local Sentry = script.Parent.Parent

local types = require(Sentry.types)
local util = require(Sentry.util)

local deepCopy = util.deepCopy
local scope: types._scope_impl = {} :: types._scope_impl
scope.__index = scope

function scope.new()
	return setmetatable({
		extras = {},
		tags = {},
		breadcrumbs = {},
		context = {},

		-- Okay luau-lsp, yes, complain about this
		level = 'info' :: 'info',
	}, scope)
end

function scope:clone()
	local newScope = scope.new()
	newScope.extras = deepCopy(self.extras)
	newScope.tags = deepCopy(self.tags)
	newScope.breadcrumbs = deepCopy(self.breadcrumbs)
	newScope.context = deepCopy(self.context)
	newScope.level = self.level

	return newScope
end

function scope:setUser(player)
	
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

local allowedLevels = {'info', 'debug', 'error', 'warning', 'fatal'}
function scope:setLevel(level)
	if not table.find(allowedLevels, level) then error("Error later") end

	-- why can a string not union??
	-- just gotta do this weird cast here
	self.level = level :: 'info'
end

function scope:setTransaction(name)
	self.transaction = name
end

function scope:clear()
	self.breadcrumbs = {}
	self.extras = {}
	self.tags = {}
	
	self.user = nil
end

function scope:clearBreadcrumbs()
	self.breadcrumbs = {}
end

function scope:applyToEvent(evet)
	
end

return scope