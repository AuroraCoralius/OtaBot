
-- some fuckery
_G.require = require
setfenv(1, _G)
Msg = print

-- loading

-- helpers
require("./libs/math_extension.lua")
require("./libs/string_extension.lua")
require("./libs/table_extension.lua")
require("./libs/misc_helpers.lua")
inspect = require("./libs/inspect.lua")
os.linux = package.config:sub(1, 1) == "/"

timer = require("timer") -- js like timers
fs = require("fs")

http = require("http")
https = require("https")
urlencode = require("querystring").stringify

json = require("json")
xml = require("./libs/xml.lua").newParser()
base64 = require("base64")

childprocess = require("childprocess")

local _, magick = pcall(require, "magick")
_G.magick = magick

-- discordia stuff
discordia = require("discordia")
enums = discordia.enums
Color = discordia.Color

-- prepare bot
client = discordia.Client()
bot = {
	config = require("./config.lua"),
	start = os.time(),
	client = client,
	notifyOwners = function(content)
		for id, _ in next, config.owners do
			client:getUser(id):send(content)
		end
	end,
	github = "https://github.com/Re-Dream/dreambot_mk2/tree/master",
	funcToGithub = function(func)
		local info = debug.getinfo(func)
		if info.source == "eval" then return info.source end
		local src = info.short_src
		local s, e = info.linedefined, info.lastlinedefined
		local cwd = process.cwd()
		return bot.github .. "/" .. src:gsub(cwd .. "/", "") .. "#L" .. s .. "-L" .. e
	end,
	errorToGithub = function(str)
		local cwd = process.cwd()
		str = str:gsub("<", "\\<")
		str = str:gsub(">", "\\>")
		str = str:gsub(cwd .. "/(.-):(%d+):?", "[%1:%2:](" .. bot.github .. "/" .. "%1#L%2)")
		return str
	end
}
config = bot.config

-- paging system
paging = require("./paging.lua")

-- commands
require("./commands.lua")
client:on("ready", function()
	local prefix = bot.commandPrefixes[1]
	client:setGame({ name = prefix .. "help" , type = 2 }) -- Listening to d$help
	-- client:setGame({ name = "you 👀", type = 3 }) -- Watching you :eyes:

	local exit_code = fs.readFileSync("exit_code")
	if exit_code and exit_code ~= "0" then
		bot.notifyOwners(":warning: Bot didn't exit cleanly, code: `" .. exit_code .. "`")
	end
end)

event = require("./events.lua")

client:run("Bot " .. config.token)

