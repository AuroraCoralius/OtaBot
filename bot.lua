
-- some fuckery
_G.require = require
setfenv(1, _G)

-- config
config = dofile("config.lua")

-- libs and helpers
dofile("libs/string_extension.lua")
dofile("libs/table_extension.lua")
dofile("libs/misc_helpers.lua")

-- luvit stuff and magick
local _, magick = pcall(require, "magick")
_G.magick = magick
urlencode = require("querystring").stringify
print = require("pretty-print").prettyPrint
https = require("https")
http = require("http")
json = require("json")
timer = require("timer")

-- discord stuff
discordia = require("discordia")
enums = discordia.enums
Color = discordia.Color
client = discordia.Client()

-- commands
dofile("commands.lua")

client:on("ready", function()
	print("Logged in as ".. client.user.username)
	client:setGame({ name = "you 👀", type = 3 })
end)
client:run("Bot " .. config.token)

