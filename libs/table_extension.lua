
function table.count(tbl)
	local count = 0
	for _ in next, tbl do
		count = count + 1
	end
	return count
end

