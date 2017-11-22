
local commands = bot.commands
local errorMsg = bot.errorMsg

commands.seecolor = {
	callback = function(msg, args)
		local guild = msg.guild
		local botMember, authorMember
		if guild then
			botMember = guild.members:get(client.user.id)
			authorMember = guild.members:get(msg.author.id)
		end

		local arg = args[1] and args[1]:gsub("#", ""):upper() or nil
		if not arg then errorMsg(msg.channel, "Invalid color! Hex format only.") return end

		local color = arg and hex2num(arg) or nil
		if not color then errorMsg(msg.channel, "Invalid color! Hex format only.") return end

		if magick and os.linux then
			local name = authorMember and authorMember.name or msg.author.username
			name = name:gsub("\\%w", "")
			fs.writeFile("last_user", name, function()
				os.execute(string.format(
						"convert -background transparent -fill '%s' -font 'Whitney-Medium' -gravity west -size 256x64 caption:@last_user seecolor.png",
						"#" .. arg
					)
				)
				coroutine.wrap(function() -- OH YEAH BABY ITS THAT TIME AGAIN
					-- Announce success!
					msg.channel:send({
						embed = {
							description = "This is what `" .. arg .. "` looks like.",
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
						description = ":arrow_left: This is what `" .. arg .. "` looks like.",
						color = color,
					},
				})
			end)()
		end
	end,
	help = "Preview a color! Accepts colors in Hex format (ex. #FF0000 = red)."
}
commands.color = {
	callback = function(msg, args)
		local guild = msg.guild
		if not guild then
			errorMsg(msg.channel, "Command only available on servers.")
			return
		end
		local botMember = guild.members:get(client.user.id)
		local authorMember = guild.members:get(msg.author.id)

		-- Do we have permissions to fuck with roles?
		if botMember:hasPermission(enums.permission.manageRoles) then
			local arg = args[1] and args[1]:gsub("#", ""):upper() or nil
			if not arg then errorMsg(msg.channel, "Invalid color! Hex format only.") return end

			local color = arg and hex2num(arg) or nil
			if not color then errorMsg(msg.channel, "Invalid color! Hex format only.") return end

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
			errorMsg(msg.channel, "Bot doesn't have permission to change roles!")
		end
	end,
	help = "Change your color! Accepts colors in Hex format (ex. #FF0000 = red)."
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
			errorMsg(msg.channel, "Bot doesn't have permission to change roles!")
		end
	end,
	help = "Reset your color."
}

