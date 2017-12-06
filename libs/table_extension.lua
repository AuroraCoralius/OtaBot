
function table.count(tbl)
	local count = 0
	for _ in next, tbl do
		count = count + 1
	end
	return count
end

function table.getlastkey(tbl)
	local lastK
	for k, v in next, tbl do
		lastK = k
	end
	return lastK
end

function table.getlastvalue(tbl)
	return tbl[table.getlastkey(tbl)]
end

local i = 0
local valueTypeEnclosure = {
	["string"] = '"%s"',
	["table"] = "<%s>",
	["function"] = "<%s>",
}
local function table_tostring(tbl, depth, inline)
	local str = "{" .. (inline and "" or "\n")
	i = i + 1
	local ourI = i
	for k, v in next, tbl do
		local lastK = k == table.getlastkey(tbl)
		str = str .. ("\t"):rep(ourI) .. "[" .. (isstring(k) and '"%s"' or "%s"):format(istable(k) and table_tostring(k, 1, true) or tostring(k)) .. "] = "
		if type(v) == "table" and ourI ~= depth then
			str = str .. table_tostring(v, depth - ourI)
		else
			str = str .. (valueTypeEnclosure[type(v)] or "%s"):format(tostring(v))
		end
		str = str .. (lastK and "" or "," .. (inline and "" or "\n"))
	end
	str = str .. (inline and "" or "\n") .. ("\t"):rep(ourI - 1) .. "}"
	return str
end
function table.tostring(tbl, depth)
	if not depth then depth = 1 end
	i = 0
	return table_tostring(tbl, depth)
end
function table.print(tbl, depth)
	print(table.tostring(tbl, depth))
end

