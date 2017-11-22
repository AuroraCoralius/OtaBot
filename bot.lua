
-- some fuckery
_G.require = require
__G = {table.unpack(_G)}
setfenv(1, _G)

-- loading

-- helpers
require("./libs/math_extension.lua")
require("./libs/string_extension.lua")
require("./libs/table_extension.lua")
require("./libs/misc_helpers.lua")
os.linux = package.config:sub(1, 1) == "/"

_print = require("pretty-print").prettyPrint -- better print

_print(debug.getinfo(require))
_print(debug.getinfo(_G.require))

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
	client = client
}

-- commands
require("./commands.lua")

client:on("ready", function()
	print("Logged in as ".. client.user.username)
	client:setGame({ name = "you 👀", type = 3 }) -- Watching you :eyes:
end)
client:run("Bot " .. config.token)

