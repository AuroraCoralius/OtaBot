-- 『 』
-- ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ
-- ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚ

local commands = bot.commands

local charMap = {}
for i = 97, 122 do
	charMap[i] = string.char(i)
end
for i = 65, 90 do
	charMap[i] = string.char(i)
end

commands.animetalk = {
	callback = function(msg, line, cmd)
		local str = "『"

		for _, char in next, line:split("") do
			local anime = charMap[char:byte()]
			print(anime)
			str = str .. (anime or char)
		end

		str = str .. "』"

		msg.channel:send(str)
	end,
	help = {
		text = "Convert text to something ressembling a Stand name from JoJo.",
	},
	category = "Fun"
}

