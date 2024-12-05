--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Soley used to redact from GitHub
local DSN = require(script.dsn)
local Sentry = require(ReplicatedStorage.Sentry)

print(Sentry.init({ dsn = DSN }))