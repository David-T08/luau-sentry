--!strict
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local SERVER_CONTEXT = RunService:IsServer()

local Sentry = script.Parent

local sdkInfo = require(Sentry.info)
local types = require(Sentry.types)
local log = require(Sentry.log)

local transport: types._transport_impl = {} :: types._transport_impl
transport.__index = transport

function transport.init(options)
	local object = {
		dsn = { protocol = "", publicKey = "", url = "", projectId = ""  }
	}

	if SERVER_CONTEXT and options.dsn then
		-- Parse DSN
		local protocol, publicKey, url, projectId = options.dsn:match("^([^:]+)://([^@]+)@([^/]+)/(%d+)$")
		if protocol and publicKey and url and projectId then
			-- Remove private key (deprecated)
			if publicKey:find(":") then
				publicKey = publicKey:match("^(%w+)") :: string
			end

			object.dsn = {
				protocol = protocol :: string,
				publicKey = publicKey :: string,
				projectId = projectId,

				url = `{protocol}://{url}/api/{projectId}`,
			}
		elseif not protocol or not publicKey or not url or not projectId then
			log.log(2, `Invalid DSN: {options.dsn}`)
		end
	end

	object.basePath = `{object.dsn.protocol}://{object.dsn.url}`
	object.envelopeSupport = options.supportsEnvelopes or false
	object.lastRequest = -1
	object.retry_after = -1

	setmetatable(object, transport)
	return object
end

local function sendRequest(self: types.Transport, path: string, body: string, envelope: boolean?): (boolean, string)
	if not SERVER_CONTEXT or self.dsn.protocol == "" then return false, '' end
	if self.lastRequest + self.retry_after > DateTime.now().UnixTimestamp then return false, `Rate Limited for: {self.retry_after} since {self.lastRequest}` end

	local auth = `Sentry sentry_version=7, sentry_key={self.dsn.publicKey}, sentry_client={sdkInfo.name}/{sdkInfo.version}`
	local httpSuccess, response = pcall(HttpService.RequestAsync, HttpService, {
		Url = `{self.dsn.url}{path}`,
		Method = 'POST',

		Headers = {
			["X-Sentry-Auth"] = auth,
			["Content-Type"] = if envelope then 'application/x-sentry-envelope' else 'application/json',
		},

		Body = body
	} :: any)

	if not httpSuccess then
		log.log(2, `[Sentry-SDK]: HttpService failed to send event: {response.StatusCode}, {response.StatusMessage}`)
		return false, 'HttpService Error'
	end

	if response.StatusCode == 429 then
		self.retry_after = response.Headers["Retry-After"] :: any
		log.log(1, `Rate limited for: {self.retry_after}`)

		return false, `Rate Limited for: {self.retry_after}`
	end

	local jsonSuccess, json = pcall(HttpService.JSONDecode, HttpService, response.Body :: string)
	local sentryError = response.Headers["X-Sentry-Error"]

	if sentryError or not response.Success then
		local message = {}
		-- The header/body may not always be present
		if sentryError then
			table.insert(message, `Sentry error: {sentryError}. `)
		else
			table.insert(message, `Unknown sentry error, code: {response.StatusCode}. `)
		end

		if json and jsonSuccess then
			table.insert(message, `Caused by: [{table.concat(json.causes, ', ')}]`)
		end

		local final = table.concat(message)
		log.log(2, final)

		return false, final
	end

	if httpSuccess and json and response.StatusCode == 200 then
		self.lastRequest = DateTime.now().UnixTimestamp
		return true, json.id
	end

	return false, `Unhandled case`
end

-- TODO: Implement envelope support
-- TODO: Implement rate limiting
-- TOOO: Implement retries
-- TODO: Implement queue
-- TODO: Implement error handling

function transport:sendEvent(eventPayload)
	return sendRequest(self, "/store/", eventPayload)
end

return transport