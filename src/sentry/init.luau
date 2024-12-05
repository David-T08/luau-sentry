local RunService = game:GetService("RunService")
local types = require(script.types)

local IS_SERVER = RunService:IsServer()

local sentry = {}
local transporter = require(script.transporter)

function sentry.init(options: types.Options)
	return transporter.init(options)	
end

function sentry.captureException(exception: string)
	
end

function sentry.captureMessage(message: string)
	
end

return sentry