
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

local curDepth = 0
local valueTypeEnclosure = {
	["string"] = '"%s"',
	["table"] = "<%s>",
	["function"] = "<%s>",
}
local function table_tostring(tbl, depth, inline)
	local str = "{" .. (inline and "" or "\n")
	curDepth = curDepth + 1
	local ourDepth = curDepth
	print(depth, curDepth, ourDepth)
	local numOnly = true
	for k in next, tbl do
		if not isnumber(k) then
			numOnly = false
			break
		end
	end
	for k, v in next, tbl do
		local lastK = k == table.getlastkey(tbl)
		str = str .. ("\t"):rep(inline and 0 or ourDepth) .. (numOnly and "" or "[" .. (isstring(k) and '"%s"' or "%s"):format(istable(k) and table_tostring(k, 1, true) or tostring(k)) .. "] = ")
		if type(v) == "table" and ourDepth ~= depth then
			str = str .. table_tostring(v, depth - ourDepth)
		else
			str = str .. (valueTypeEnclosure[type(v)] or "%s"):format(tostring(v))
		end
		str = str .. (lastK and "" or "," .. (inline and " " or "\n"))
	end
	str = str .. (inline and "" or "\n") .. ("\t"):rep(inline and 0 or ourDepth - 1) .. "}"
	return str
end
function table.tostring(tbl, depth)
	if not depth then depth = 1 end
	curDepth = 0
	return table_tostring(tbl, depth)
end
function table.print(tbl, depth)
	print(table.tostring(tbl, depth))
end

