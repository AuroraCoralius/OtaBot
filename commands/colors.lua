
local commands = bot.commands

local invalidColorErr = "Invalid color! Hex/RGB format only."
local function figureOutColor(r, g, b)
	local hex, color
	if r and g and b then
		hex = rgb2hex(r, g, b)
		if not hex then return false, invalidColorErr end

		color = hex2num(hex)
		if not color then return false, invalidColorErr end

		hex = ("%s, %s, %s"):format(tonumber(r:trim()), tonumber(g:trim()), tonumber(b:trim()))
	elseif r and not g and not b then
		hex = hex2string(r)
		if not hex then return false, invalidColorErr end

		color = hex2num(hex)
		if not color then return false, invalidColorErr end
	else
		return false, invalidColorErr
	end

	return color, hex
end
commands.seecolor = {
	callback = function(msg, line, hex, g, b)
		local color, hex = figureOutColor(hex, g, b)
		if not color then return false, hex end

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
				os.execute(("convert -background transparent -fill '%s' -font 'Whitney-Medium' -gravity west -size 256x64 caption:@last_user seecolor.png"):format("#" .. num2hex(color)))
				coroutine.wrap(function()
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
		usage = "`{prefix}{cmd} <color in Hexadecimal or RGB format>`\nYou can grab Hex/RGB color codes from [there](http://htmlcolorcodes.com/color-picker/).",
		example = "`{prefix}{cmd} #FF0000`, `{prefix}{cmd} FF0000` or `{prefix}{cmd} 255,0,0` will show your name in red."
	},
	category = "Colors"
}

local function cleanColorRoles(member)

	if member then
		local botMember = member.guild.members:get(client.user.id)
		if botMember:hasPermission(enums.permission.manageRoles) then
			for role in member.roles:iter() do
				if role.name:match("^#") then
					member:removeRole(role.id)
					if #role.members < 1 then
						role:delete()
					end
				end
			end
		end
	else
		for guild in client.guilds:iter() do
			local botMember = guild.members:get(client.user.id)
			if botMember:hasPermission(enums.permission.manageRoles) then
				local lowestPos = math.huge
				for role in botMember.roles:iter() do
					if role.name:lower() ~= "@everyone" and role.position < lowestPos then
						lowestPos = role.position
					end
				end
				for role in guild.roles:iter() do
					if role.name:match("^#") and #role.members < 1 and role.position < lowestPos then
						role:delete()
					end
				end
			end
		end
	end
end
commands.color = {
	callback = function(msg, line, hex, g, b)
		local guild = msg.guild
		if not guild then
			return false, "You can only use this command in a guild."
		end

		local botMember = guild.members:get(client.user.id)
		local authorMember = guild.members:get(msg.author.id)

		if not authorMember then return false, "Webhooks unsupported." end

		-- Do we have permissions to fuck with roles?
		if botMember:hasPermission(enums.permission.manageRoles) then
			local color, hex = figureOutColor(hex, g, b)
			if not color then return false, hex end

			-- Remove other color roles you had...
			cleanColorRoles(authorMember)

			-- Find role...
			local role
			for _role in guild.roles:iter() do
				if _role.name:match("^#" .. num2hex(color)) then
					role = _role
					break
				end
			end
			-- If it doesn't exist, make it!
			if not role then
				role = guild:createRole("#" .. num2hex(color))
				-- local roleColor = Color(color) -- unnecessary
				role:setColor(color)
				local lowestPos = math.huge
				for role in botMember.roles:iter() do
					if role.name:lower() ~= "@everyone" and role.position < lowestPos then
						lowestPos = role.position
					end
				end
				local pos = math.max(1, lowestPos - 2) -- 2 because it's position is 1 and we want to be BELOW its highest role
				role:moveUp(pos)
			end

			-- Set role.
			authorMember:addRole(role.id)

			-- Announce success!
			msg.channel:send({
				embed = {
					description = "**" .. authorMember.fullname .. "**'s color is now <@&" .. role.id .. ">.",
					color = color
				}
			})
		else
			return false, "Bot doesn't have permission to manage roles!"
		end
	end,
	help = {
		text = "Set your name color! Gives you a role with the supplied color.",
		usage = "`{prefix}{cmd} <color in Hexadecimal or RGB format>`\nYou can grab Hex/RGB color codes from [there](http://htmlcolorcodes.com/color-picker/).",
		example = "`{prefix}{cmd} #FF0000`, `{prefix}{cmd} FF0000` or `{prefix}{cmd} 255,0,0` will set your name color to red."
	},
	category = "Colors"
}
commands.resetcolor = {
	callback = function(msg)
		local guild = msg.guild
		if not guild then
			return false, "You can only use this command in a guild."
		end

		local botMember = guild.members:get(client.user.id)
		local authorMember = guild.members:get(msg.author.id)

		if not authorMember then return false, "Webhooks unsupported." end

		-- Do we have permissions to fuck with roles?
		if botMember:hasPermission(enums.permission.manageRoles) then
			-- Remove your color roles...
			cleanColorRoles(authorMember)

			-- Announce success!
			msg.channel:send({
				embed = {
					description = "**" .. authorMember.fullname .. "**'s color has been reset.",
					color = 0x7FFF40
				}
			})
		else
			return false, "Bot doesn't have permission to change roles!"
		end
	end,
	help = "Reset your color.",
	category = "Colors"
}
timer.setInterval(60 * 60 * 1000, function()
	coroutine.wrap(function()
		cleanColorRoles()
	end)()
end)
client:on("ready", function()
	cleanColorRoles()
end)

