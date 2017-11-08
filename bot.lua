
local config = dofile("config.lua")
dofile("libs/string_extension.lua")
local prettyPrint = require("pretty-print")

local discordia = require("discordia")
local enums = discordia.enums
local Color = discordia.Color
local client = discordia.Client()

client:on("ready", function()
	print("Logged in as ".. client.user.username)
end)

local hex2rgb = function(hex)
    hex = hex:gsub("#", "")
    if hex:len() == 3 then
        return tonumber("0x" .. hex:sub(1, 1)) * 17, tonumber("0x" .. hex:sub(2, 2)) * 17, tonumber("0x" .. hex:sub(3, 3)) * 17
    elseif hex:len() == 6 then
        return tonumber("0x" .. hex:sub(1, 2)), tonumber("0x" .. hex:sub(3, 4)), tonumber("0x" .. hex:sub(5, 6))
    end
end
local hex2num = function(hex)
	hex = hex:gsub("#", "")
	if hex:len() == 3 then
		return tonumber("0x" .. hex:sub(1, 3))
	elseif hex:len() == 6 then
		return tonumber("0x" .. hex:sub(1, 6))
	end
end

local cmdPrefix = "^[%.!/]"
local commands = {
	color = {
		callback = function(msg, args)
			local guild = msg.guild
			local botMember = guild.members:get(client.user.id)
			local authorMember = guild.members:get(msg.author.id)

			-- Do we have permissions to fuck with roles?
			if botMember:hasPermission(enums.permission.manageRoles) then
				local color = args[1] and hex2num(args[1]) or nil
				if color then
					-- Remove other color roles you had...
					for role in authorMember.roles:iter() do
						if role.name:match("^#") then
							authorMember:removeRole(role.id)
						end
					end

					-- Find role...
					local role
					for _role in guild.roles:iter() do
						if _role.name:match("#" .. args[1]) then
							role = _role
							break
						end
					end
					-- If it doesn't exist, make it!
					if not role then
						role = guild:createRole("#" .. args[1])
						-- local roleColor = Color(color) -- unnecessary
						role:setColor(color)
					end

					-- Set role.
					authorMember:addRole(role.id)

					-- Announce success!
					msg.channel:send({
						embed = {
							description = authorMember.fullname .. "'s color is now `" .. args[1] .. "`.",
							color = color
						}
					})
				end
			end
		end
	}
}
client:on("messageCreate", function(msg)
	local text = msg.content
	local prefix = text:match(cmdPrefix)
	if prefix then
		local args = text:split(" ")
		local cmd = args[1]:sub(prefix:len() + 1)
		table.remove(args, 1)
		cmdData = commands[cmd]

		if cmdData then
			cmdData.callback(msg, args)
		end
	end
end)

client:run("Bot " .. config.token)

