
_G.require = require
setfenv(1, _G)

local config = dofile("config.lua")
local _, magick = pcall(require("magick"))
dofile("libs/string_extension.lua")
local prettyPrint = require("pretty-print")

discordia = require("discordia")
enums = discordia.enums
Color = discordia.Color
client = discordia.Client()

client:on("ready", function()
	print("Logged in as ".. client.user.username)
end)

hex2rgb = function(hex)
	hex = hex:gsub("#", "")
	if hex:len() == 3 then
		return tonumber("0x" .. hex:sub(1, 1)) * 17, tonumber("0x" .. hex:sub(2, 2)) * 17, tonumber("0x" .. hex:sub(3, 3)) * 17
	elseif hex:len() == 6 then
		return tonumber("0x" .. hex:sub(1, 2)), tonumber("0x" .. hex:sub(3, 4)), tonumber("0x" .. hex:sub(5, 6))
	end
end
hex2num = function(hex)
	hex = hex:gsub("#", "")
	if hex:len() == 3 then
		return tonumber("0x" .. hex:sub(1, 1) .. hex:sub(1, 1) .. hex:sub(2, 2) .. hex:sub(2, 2) .. hex:sub(3, 3) .. hex:sub(3, 3))
	elseif hex:len() == 6 then
		return tonumber("0x" .. hex:sub(1, 6))
	end
end

local function errorChat(channel, msg, title)
	channel:send({
		embed = {
			title = title,
			description = msg,
			color = 0xFF4040
		}
	})
end
local cmdPrefix = "^[%.!/%$]"
commands = {
	eval = {
		callback = function(msg, args, line)
			local guild = msg.guild
			local botMember = guild.members:get(client.user.id)
			local authorMember = guild.members:get(msg.author.id)

			-- if authorMember:hasPermission(enums.permission.manageGuild) then
			if authorMember.id == "138685670448168960" then
				local func, err = loadstring(line)
				if type(func) == "function" then
					local _msg = {}
					local ok, ret = pcall(func)
					if not ok then
						errorChat(msg.channel, ret, "Lua Error:")
						return
					end
					if ret then
						_msg.embed = {
							title = "Result:",
							description = "```lua\n" .. tostring(ret) .. "\n```",
							color = 0x9B65BD
						}
					else
						_msg.content = ":white_check_mark:"
					end
					msg.channel:send(_msg)
				else
					errorChat(msg.channel, err, "Lua Error:")
				end
			else
				errorChat(msg.channel, "No access!")
			end
		end,
		help = "Runs Lua. [admin only]"
	},
	seecolor = {
		callback = function(msg, args)
			local guild = msg.guild
			local botMember = guild.members:get(client.user.id)
			local authorMember = guild.members:get(msg.author.id)

			local arg = args[1] and args[1]:gsub("#", ""):upper() or nil
			if not arg then errorChat(msg.channel, "Invalid color! Hex format only.") return end

			local color = arg and hex2num(arg) or nil
			if not color then errorChat(msg.channel, "Invalid color! Hex format only.") return end

			if magick then
				os.execute(string.format('echo -n "%s" > last_user', authorMember.name))
				os.execute(string.format(
						"convert -background transparent -fill '%s' -font 'Whitney-Medium' -gravity west -size 256x64 caption:@last_user seecolor.png",
						"#" .. arg
					)
				)
			end
			-- Announce success!
			msg.channel:send({
				embed = {
					description = "This is what `" .. arg .. "` looks like.",
					color = color,
				},
				file = magick and "seecolor.png" or nil
			})
		end,
		help = "Preview a color! Accepts colors in Hex format (ex. #FF0000 = red)."
	},
	color = {
		callback = function(msg, args)
			local guild = msg.guild
			local botMember = guild.members:get(client.user.id)
			local authorMember = guild.members:get(msg.author.id)

			-- Do we have permissions to fuck with roles?
			if botMember:hasPermission(enums.permission.manageRoles) then
				local arg = args[1] and args[1]:gsub("#", ""):upper() or nil
				if not arg then errorChat(msg.channel, "Invalid color! Hex format only.") return end

				local color = arg and hex2num(arg) or nil
				if not color then errorChat(msg.channel, "Invalid color! Hex format only.") return end

				-- Remove other color roles you had...
				for role in authorMember.roles:iter() do
					if role.name:match("^#") then
						authorMember:removeRole(role.id)
					end
				end

				-- Find role...
				local role
				for _role in guild.roles:iter() do
					if _role.name:match("#" .. arg) then
						role = _role
						break
					end
				end
				-- If it doesn't exist, make it!
				if not role then
					role = guild:createRole("#" .. arg)
					-- local roleColor = Color(color) -- unnecessary
					role:setColor(color)
					role:moveUp() -- show above Tenno role
				end

				-- Set role.
				authorMember:addRole(role.id)

				-- Announce success!
				msg.channel:send({
					embed = {
						description = authorMember.fullname .. "'s color is now `" .. arg .. "`.",
						color = color
					}
				})
			else
				errorChat(msg.channel, "Bot doesn't have permission to change roles!")
			end
		end,
		help = "Change your color! Accepts colors in Hex format (ex. #FF0000 = red)."
	},
	resetcolor = {
		callback = function(msg)
			local guild = msg.guild
			local botMember = guild.members:get(client.user.id)
			local authorMember = guild.members:get(msg.author.id)

			-- Do we have permissions to fuck with roles?
			if botMember:hasPermission(enums.permission.manageRoles) then
				-- Remove other color roles you had...
				for role in authorMember.roles:iter() do
					if role.name:match("^#") then
						authorMember:removeRole(role.id)
					end
				end

				-- Announce success!
				msg.channel:send({
					embed = {
						description = authorMember.fullname .. "'s color has been reset.",
						color = 0x7FFF40
					}
				})
			else
				errorChat(msg.channel, "Bot doesn't have permission to change roles!")
			end
		end,
		help = "Reset your color."
	}
}
commands.help = {
	callback = function(msg)
		local guild = msg.guild
		local botMember = guild.members:get(client.user.id)
		local authorMember = guild.members:get(msg.author.id)

		local _msg = {
			embed = {
				description = "Available commands:",
				fields = {},
				color = 0x9B65BD
			}
		}
		for cmd, cmdData in next, commands do
			local fields = _msg.embed.fields
			fields[#fields + 1] = {
				name = cmd,
				value = cmdData.help
			}
		end

		msg.channel:send(_msg)
	end,
	help = "Displays this."
}
client:on("messageCreate", function(msg)
	local text = msg.content
	local prefix = text:match(cmdPrefix)
	if prefix then
		local args = text:split(" ")
		local cmd = args[1]:sub(prefix:len() + 1)
		local line = text:sub(args[1]:len() + 2)
		table.remove(args, 1)
		cmdData = commands[cmd]

		if cmdData then
			cmdData.callback(msg, args, line)
		end
	end
end)

client:run("Bot " .. config.token)

