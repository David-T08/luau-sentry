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

function util.elementCount(tbl: any?): number
	if not tbl then return 0 end

	local count = 0
	for _ in pairs(tbl) do
		count += 1
	end
	return count
end

function util.removeIfEmpty<T>(tbl: T): T?
	if not tbl then return nil end
	if util.elementCount(tbl) == 0 then return nil end

	return tbl
end


return util