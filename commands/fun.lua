
local commands = bot.commands

local fw = "𝑨 𝑩 𝑪 𝑫 𝑬 𝑭 𝑮 𝑯 𝑰 𝑱 𝑲 𝑳 𝑴 𝑵 𝑶 𝑷 𝑸 𝑹 𝑺 𝑻 𝑼 𝑽 𝑾 𝑿 𝒀 𝒁"
local charMap = {}
for i, c in next, fw:split(" ") do
	charMap[64 + i] = { string.byte(c, 1, 9) }
end

commands.stand = {
	callback = function(msg, line)
		local str = "『 " .. line .. " 』"

		-- props to string.anime from Metastruct
		str = str:upper()
		-- str = str:gsub("%l", function(c) return string.char(239, 189, 130 + (c:byte() - 98)) end)
		str = str:gsub("%u", function(c) return
			-- string.char(239, 188, 161 + (c:byte() - 65)) -- OG fullwidth
			string.char(unpack(charMap[c:byte()]))
		end)

		msg.channel:send(str)
	end,
	help = {
		text = "Converts text to something ressembling a Stand name from JoJo.",
		usage = "{prefix}{cmd} <any text>",
		example = "{prefix}{cmd} Star Platinum"
	},
	category = "Fun"
}

