
local commands = bot.commands
local errorMsg = bot.errorMsg

commands.seecolor = {
	callback = function(msg, line, hex)
		hex = hex2string(hex)
		if not hex then errorMsg(msg.channel, "Invalid color! Hex format only.") return end

		local color = hex2num(hex)
		if not color then errorMsg(msg.channel, "Invalid color! Hex format only.") return end

		local guild = msg.guild
		local botMember, authorMember
		if guild then
			botMember = guild.members:get(client.user.id)
			authorMember = guild.members:get(msg.author.id)
		end

		if magick and os.linux then
			local name = authorMember and authorMember.name or msg.author.username
			name = name:gsub("\\%w", "")
			fs.writeFile("last_user", name, function()
				os.execute(string.format(
						"convert -background transparent -fill '%s' -font 'Whitney-Medium' -gravity west -size 256x64 caption:@last_user seecolor.png",
						"#" .. hex
					)
				)
				coroutine.wrap(function() -- OH YEAH BABY ITS THAT TIME AGAIN
					-- Announce success!
					msg.channel:send({
						embed = {
							description = "This is what `" .. hex .. "` looks like.",
							color = color,
						},
						file = magick and "seecolor.png" or nil
					})
				end)()
			end)
		else
			coroutine.wrap(function()
				-- Announce success!
				msg.channel:send({
					embed = {
						description = ":arrow_left: This is what `" .. hex .. "` looks like.",
						color = color,
					},
				})
			end)()
		end
	end,
	help = {
		text = "Preview a color!",
		usage = "`{prefix}seecolor <color in Hexadecimal format>`\nYou can grab Hex color codes from [there](http://htmlcolorcodes.com/color-picker/).",
		example = "`{prefix}seecolor #FF0000` or `{prefix}seecolor FF0000` will show your name in red."
	}
}
local function cleanColorRoles(member)
	for role in member.roles:iter() do
		if role.name:match("^#") then
			member:removeRole(role.id)
			if #role.members < 1 then
				role:delete()
			end
		end
	end
end
commands.color = {
	callback = function(msg, line, hex)
		local guild = msg.guild
		if not guild then
			errorMsg(msg.channel, "Command only available on servers.")
			return
		end
		local botMember = guild.members:get(client.user.id)
		local authorMember = guild.members:get(msg.author.id)

		-- Do we have permissions to fuck with roles?
		if botMember:hasPermission(enums.permission.manageRoles) then
			hex = hex2string(hex)
			if not hex then errorMsg(msg.channel, "Invalid color! Hex format only.") return end

			local color = hex2num(hex)
			if not color then errorMsg(msg.channel, "Invalid color! Hex format only.") return end

			-- Remove other color roles you had...
			cleanColorRoles(authorMember)

			-- Find role...
			local role
			for _role in guild.roles:iter() do
				if _role.name:match("#" .. hex) then
					role = _role
					break
				end
			end
			-- If it doesn't exist, make it!
			if not role then
				role = guild:createRole("#" .. hex)
				-- local roleColor = Color(color) -- unnecessary
				role:setColor(color)
				local highestPos = 0
				for role in botMember.roles:iter() do
					if role.position > highestPos then
						highestPos = role.position
					end
				end
				local pos = math.max(1, highestPos - 4) -- 4 because it's position is 1 and we want to be BELOW its highest role
				print(role:moveUp(pos))
			end

			-- Set role.
			authorMember:addRole(role.id)

			-- Announce success!
			msg.channel:send({
				embed = {
					description = authorMember.fullname .. "'s color is now `" .. hex .. "`.",
					color = color
				}
			})
		else
			errorMsg(msg.channel, "Bot doesn't have permission to change roles!")
		end
	end,

	help = {
		text = "Set your name color! Gives you a role with the supplied color.",
		usage = "`{prefix}color <color in Hexadecimal format>`\nYou can grab Hex color codes from [there](http://htmlcolorcodes.com/color-picker/).",
		example = "`{prefix}color #FF0000` or `{prefix}color FF0000` will set your name color to red."
	}
}
commands.resetcolor = {
	callback = function(msg)
		local guild = msg.guild
		if not guild then
			errorMsg(msg.channel, "Command only available on servers.")
			return
		end
		local botMember = guild.members:get(client.user.id)
		local authorMember = guild.members:get(msg.author.id)

		-- Do we have permissions to fuck with roles?
		if botMember:hasPermission(enums.permission.manageRoles) then
			-- Remove your color roles...
			cleanColorRoles(authorMember)

			-- Announce success!
			msg.channel:send({
				embed = {
					description = authorMember.fullname .. "'s color has been reset.",
					color = 0x7FFF40
				}
			})
		else
			errorMsg(msg.channel, "Bot doesn't have permission to change roles!")
		end
	end,
	help = "Reset your color."
}

