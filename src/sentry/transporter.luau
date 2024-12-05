--!strict
local RunService = game:GetService("RunService")

local transporter = {}

function transporter.init(options: { dsn: string })
	-- Parse DSN
	local protocol, publicKey, url, projectId = options.dsn:match("^([^:]+)://([^@]+)@([^/]+)/(%d+)$")
	if not protocol or not publicKey or not url or not projectId then
		error("Invalid DSN")
	end

	-- Remove private key (deprecated)
	if publicKey:find(":") then
		publicKey = publicKey:match("^(%w+)")
	end


end

return transporter