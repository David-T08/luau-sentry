--!strict
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local SERVER_CONTEXT = RunService:IsServer()

local sdkInfo = require(script.Parent.info)
local types = require(script.Parent.types)

local transporter: types._transporter_impl = {} :: types._transporter_impl
transporter.__index = transporter

function transporter.init(options)
	local object = {
		dsn = { protocol = "", publicKey = "", url = "", projectId = ""  }
	}

	if SERVER_CONTEXT and options.dsn then
		-- Parse DSN
		local protocol, publicKey, url, projectId = options.dsn:match("^([^:]+)://([^@]+)@([^/]+)/(%d+)$")
		if not protocol or not publicKey or not url or not projectId then
			error("Invalid DSN")
		end
	
		-- Remove private key (deprecated)
		if publicKey:find(":") then
			publicKey = publicKey:match("^(%w+)") :: string
		end

		object.dsn = {
			protocol = protocol :: string,
			publicKey = publicKey :: string,
			projectId = projectId,
			
			url = `{protocol}://{url}`,
		}
	
	elseif not SERVER_CONTEXT then
		
	end

	object.basePath = `{object.dsn.protocol}://{object.dsn.url}`
	object.envelopeSupport = options.supportsEnvelopes or false
	object.lastRequest = -1
	object.retry_after = -1

	setmetatable(object, transporter)
	return object
end



-- function transporter:_

return transporter