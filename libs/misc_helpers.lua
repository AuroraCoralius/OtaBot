
for _, _type in next, {	"table", "string", "number", "function" } do
	_G["is" .. _type] = function(val)
		return type(val) == _type
	end
end

function _G.hex2rgb(hex)
	if not isstring(hex) then return end
	hex = hex:gsub("#", "")
	if hex:len() == 3 then
		return tonumber("0x" .. hex:sub(1, 1)) * 17, tonumber("0x" .. hex:sub(2, 2)) * 17, tonumber("0x" .. hex:sub(3, 3)) * 17
	elseif hex:len() == 6 then
		return tonumber("0x" .. hex:sub(1, 2)), tonumber("0x" .. hex:sub(3, 4)), tonumber("0x" .. hex:sub(5, 6))
	end
end
function _G.hex2num(hex)
	if not isstring(hex) then return end
	hex = hex:gsub("#", ""):upper()
	if hex:len() == 3 then
		return tonumber("0x" .. hex:sub(1, 1) .. hex:sub(1, 1) .. hex:sub(2, 2) .. hex:sub(2, 2) .. hex:sub(3, 3) .. hex:sub(3, 3))
	elseif hex:len() == 6 then
		return tonumber("0x" .. hex:sub(1, 6))
	end
end
function _G.hex2string(hex)
	if not isstring(hex) then return end
	hex = hex:gsub("#", ""):upper()
	if hex:len() == 3 then
		return hex:sub(1, 1) .. hex:sub(1, 1) .. hex:sub(2, 2) .. hex:sub(2, 2) .. hex:sub(3, 3) .. hex:sub(3, 3)
	elseif hex:len() == 6 then
		return hex
	end
end

function _G.sortedPairs(tbl)
	local keys = {}
	for k, _ in next, tbl do
		table.insert(keys, k)
	end
	table.sort(keys)
	local i = 0
	local iter = function()
		i = i + 1
		if keys[i] ~= nil then
			return keys[i], tbl[keys[i]]
		end
	end
	return iter
end

function debug.getupvalues(func)
	local info = debug.getinfo(func)
	local ups = {}
	for i = 1, info.nups do
		ups[#ups + 1] = { debug.getupvalue(func, i) }
	end
	return ups
end

function debug.getparams(func)
	return debug.getinfo(func).nparams
end

