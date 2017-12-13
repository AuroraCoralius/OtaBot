
function string.totable(str)
	local tbl = {}

	for i = 1, str:len() do
		tbl[i] = str:sub(i, i)
	end

	return tbl
end

function string.explode(separator, str, patterns)
	if separator == "" then return str:totable() end

	local ret = {}
	local pos = 1

	for i = 1, str:len() do
		local startPos, endPos = str:find(separator, pos, not patterns)
		if not startPos then break end
		ret[i] = str:sub(pos, startPos - 1)
		currentPos = endPos + 1
	end

	ret[#ret + 1] = str:sub(pos)

	return ret
end

function string.split(str, delimiter)
	return string.explode(delimiter, str)
end

function string.urlencode(str)
	if str then
    	str = str:gsub("\n", "\r\n")
    	str = str:gsub("([^%w ])",
    		function(c) return string.format("%%%02X", string.byte(c)) end
    	)
    	str = str:gsub(" ", "+")
	end
	return str
end

function string.trim(str)
	return str:gsub("^%s*(.-)%s*$", "%1")
end

