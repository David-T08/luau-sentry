--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Soley used to redact from GitHub
local DSN = require(script.dsn)
local Sentry = require(ReplicatedStorage.Sentry)

local ServerLogger = Sentry.init({
	dsn = DSN
}, "Server")

print(ServerLogger:currentHub())
print(ServerLogger:globalHub())

ServerLogger:configureScope(function(scope)
	
end)
