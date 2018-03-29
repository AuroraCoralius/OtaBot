
for _, _type in next, {	"table", "string", "number", "function" } do
	_G["is" .. _type] = function(val)
		return type(val) == _type
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

