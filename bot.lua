
-- some fuckery
_G.require = require
setfenv(1, _G)

-- loading

-- helpers
dofile("libs/math_extension.lua")
dofile("libs/string_extension.lua")
dofile("libs/table_extension.lua")
dofile("libs/misc_helpers.lua")
os.linux = package.config:sub(1, 1) == "/"

_print = require("pretty-print").prettyPrint -- better print

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
dofile("commands.lua")

client:on("ready", function()
	print("Logged in as ".. client.user.username)
	client:setGame({ name = "you 👀", type = 3 }) -- Watching you :eyes:
end)
client:run("Bot " .. config.token)

