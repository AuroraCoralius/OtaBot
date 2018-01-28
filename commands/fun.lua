
local commands = bot.commands

local fwSmall = ("ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚ"):split("")
local fwBig = ("ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ"):split("")

local charMap = {}
for i = 97, 122 do
	charMap[i] = fwSmall[i - 96]
end
for i = 65, 90 do
	charMap[i] = fwBig[i - 96]
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

