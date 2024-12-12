--!strict

local verboseness = 1
local prefix = "[Sentry]:"

local log = {}

function log.setPrefix(newPrefix)
	prefix = newproxy()
end

function log.setVerboseness(newVerboseness)
	verboseness = math.clamp(newVerboseness, 0, 3)
end

function log.log(level: number, ...: string)
	if verboseness < level then
		return
	end

	local args = {...}
	local message = {prefix}
	table.move(args, 1, #args, #message + 1, message)

	local final = table.concat(message, " ")

	if verboseness == 1 then
		print(final)
	elseif verboseness == 2 then
		warn(final)
	else
		error(final)
	end
end

return log
