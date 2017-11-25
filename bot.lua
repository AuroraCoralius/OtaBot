
-- some fuckery
_G.require = require
setfenv(1, _G)
__G = {table.unpack(_G)}

-- loading

-- helpers
require("./libs/math_extension.lua")
require("./libs/string_extension.lua")
require("./libs/table_extension.lua")
require("./libs/misc_helpers.lua")
os.linux = package.config:sub(1, 1) == "/"

pprint = require("pretty-print").prettyPrint -- better print

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
config = require("./config.lua")

client = discordia.Client()
bot = {
	start = os.time(),
	client = client,
	notifyOwners = function(content)
		for id, _ in next, config.owners do
			client:getUser(id):send(content)
		end
	end
}

-- commands
require("./commands.lua")

client:on("ready", function()
	client:setGame({ name = "you 👀", type = 3 }) -- Watching you :eyes:
	local exit_code = fs.readFileSync("exit_code")
	if exit_code and exit_code ~= "0" then
		bot.notifyOwners(":warning: Bot didn't exit cleanly, code: `" .. exit_code .. "`")
	end
end)

require("./events.lua")

client:run("Bot " .. config.token)

