
-- https://gist.github.com/jaredallard/ddb152179831dd23b230
function string.split(self, delimiter)
	local result = {}
	local from = 1
	local delim_from, delim_to = string.find(self, delimiter, from)
	while delim_from do
		result[#result + 1] = string.sub(self, from, delim_from - 1)
		from = delim_to + 1
		delim_from, delim_to = string.find(self, delimiter, from)
	end
	result[#result + 1] = string.sub(self, from)
	return result
end

