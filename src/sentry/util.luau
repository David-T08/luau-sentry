--!strict

local util = {}

function util.deepCopy<T>(tbl: T): T
	if not tbl then return nil :: any end
	local copy = {}

	for key, value in pairs(tbl :: any) do
		if type(value) == "table" then
			copy[key] = util.deepCopy(value)
		else
			copy[key] = value
		end
	end

	return copy :: any 
end


return util