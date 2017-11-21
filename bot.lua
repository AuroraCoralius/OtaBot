
-- some fuckery
_G.require = require
setfenv(1, _G)

-- config
config = require("./config.lua")

-- libs and helpers
require("./libs/math_extension.lua")
require("./libs/string_extension.lua")
require("./libs/table_extension.lua")
require("./libs/misc_helpers.lua")
require("./libs/xml.lua")

-- luvit stuff and magick
local _, magick = pcall(require, "magick")
_G.magick = magick
xml = xml.newParser()
base64 = require("base64")
urlencode = require("querystring").stringify
print = require("pretty-print").prettyPrint
https = require("https")
http = require("http")
json = require("json")
timer = require("timer")
fs = require("fs")

-- discord stuff
discordia = require("discordia")
enums = discordia.enums
Color = discordia.Color
client = discordia.Client()

bot = {
	start = os.time(),
	client = client
}

-- commands
require("./commands.lua")

client:on("ready", function()
	print("Logged in as ".. client.user.username)
	client:setGame({ name = "you 👀", type = 3 })
end)
client:run("Bot " .. config.token)

