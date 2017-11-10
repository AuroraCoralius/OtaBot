
-- parsing
local cmdPrefix = "^[%.!/%$]"
local cmdArgGrouper = "[\"']"
local cmdArgSeparators = "[%s,]"
local cmdEscapeChar = "[\\]"
function parseArgs(str) -- from mingeban2
	local chars = str:split("")
	local grouping = false
	local escaping = false
	local grouper = false
	local separator = false
	local arg = ""
	local ret = {}

	for k, c in next, chars do
		local cont = true

		local before = chars[k - 1] -- check if there's anything behind the current char
		local after = chars[k + 1] -- check if there's anything after the current char

		if c:match(cmdEscapeChar) then
			escaping = true
			cont = false -- we're escaping a char, no need to continue
		end

		if cont then
			if ((arg ~= "" and grouping) or (arg == "" and not grouping)) and c:match(grouper or cmdArgGrouper) then -- do we try to group
				if not before or before and not escaping then -- are we escaping or starting a command
					if not grouper then
						grouper = c -- pick the current grouper
					end
					grouping = not grouping -- toggle group mode
					if arg ~= "" then
						ret[#ret + 1] = arg -- finish the job, add arg to list
						arg = "" -- reset arg
					end
					cont = false -- we toggled grouping mode
				elseif escaping then
					escaping = false -- we escaped the character, disable it
				end
			end

			if cont then
				if c:match(separator or cmdArgSeparators) and not grouping then -- are we separating and not grouping
					if not separator then
						separator = c -- pick the current separator
					end
					if before and not before:match(grouper or cmdArgGrouper) then -- arg ~= "" then
						ret[#ret + 1] = arg -- finish the job, add arg to list
						arg = "" -- reset arg
					end
					cont = false -- let's get the next arg going
				end

				if cont then
					arg = arg .. c -- go on with the arg
					if not after then -- in case this is the end of the sentence, add last thing written
						ret[#ret + 1] = arg
					end
				end

			end
		end
	end

	return ret -- give results!!
end

local function errorChat(channel, msg, title)
	channel:send({
		embed = {
			title = title,
			description = type(msg) == "string" and msg or nil,
			fields = type(msg) == "table" and { msg } or nil,
			color = 0xFF4040
		}
	})
end

-- command callbacks
commands = {
	[{"tr", "translate", "тр"}] = {
		callback = function(msg, args, line)
			if not config.yandex_api then errorChat("No Yandex API key provided.") return end

			local _msg = {}

			local lang = args[2] and args[2]:lower() or "en"
			local get = urlencode({
				key = config.yandex_api,
				lang = lang,
				text = args[1]
			})

			local url = "https://translate.yandex.net/api/v1.5/tr.json/translate?" .. get
			local req = https.get(url, function(res)
				res:on("data", function(body)
					local data = json.decode(body)
					if data.code == 200 then
						_msg.embed = {
							title = "Translation to `" .. data.lang .. "`",
							description = data.text[1],
							footer = {
								icon_url = client.user.avatarURL,
								text = "Yandex Translate API - code " .. data.code
							},
							color = 0x00FFC0
						}
					else
						_msg.embed = {
							title = "Error:",
							description = data.message,
							footer = {
								icon_url = client.user.avatarURL,
								text = "Yandex Translate API - code " .. data.code .. " - lang " .. lang
							},
							color = 0xFF4040
						}
					end
					coroutine.wrap(function()
						msg.channel:send(_msg) -- well this is ass.
					end)()
				end)
			end)
		end,
		help = "Translate stuff."
	},
	eval = {
		callback = function(msg, args, line)
			--[[
			local guild = msg.guild
			local botMember, authorMember
			if guild then
				botMember = guild.members:get(client.user.id)
				authorMember = guild.members:get(msg.author.id)
			end

			-- if authorMember:hasPermission(enums.permission.manageGuild) then
			]]
			if config.owners[msg.author.id] then
				_G.self = client
				_G.msg = msg
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
			_G.self = nil
			_G.msg = nil
		end,
		help = "Runs Lua. [owner only]"
	},
	seecolor = {
		callback = function(msg, args)
			local guild = msg.guild
			local botMember, authorMember
			if guild then
				botMember = guild.members:get(client.user.id)
				authorMember = guild.members:get(msg.author.id)
			end

			local arg = args[1] and args[1]:gsub("#", ""):upper() or nil
			if not arg then errorChat(msg.channel, "Invalid color! Hex format only.") return end

			local color = arg and hex2num(arg) or nil
			if not color then errorChat(msg.channel, "Invalid color! Hex format only.") return end

			if magick then
				local name = authorMember and authorMember.name or msg.author.username
				name = name:gsub("\\%w", "")
				fs.writeFile("last_user", name, function()
					os.execute(string.format(
							"convert -background transparent -fill '%s' -font 'Whitney-Medium' -gravity west -size 256x64 caption:@last_user seecolor.png",
							"#" .. arg
						)
					)
					-- Announce success!
					msg.channel:send({
						embed = {
							description = "This is what `" .. arg .. "` looks like.",
							color = color,
						},
						file = magick and "seecolor.png" or nil
					})
				end)
			else
				-- Announce success!
				msg.channel:send({
					embed = {
						description = ":arrow_left: This is what `" .. arg .. "` looks like.",
						color = color,
					},
					file = magick and "seecolor.png" or nil
				})
			end
		end,
		help = "Preview a color! Accepts colors in Hex format (ex. #FF0000 = red)."
	},
	color = {
		callback = function(msg, args)
			local guild = msg.guild
			if not guild then
				errorChat(msg.channel, "Command only available on servers.")
				return
			end
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
			if not guild then
				errorChat(msg.channel, "Command only available on servers.")
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
				errorChat(msg.channel, "Bot doesn't have permission to change roles!")
			end
		end,
		help = "Reset your color."
	}
}
commands.help = {
	callback = function(msg)
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
				name = type(cmd) == "table" and table.concat(cmd, ", ") or cmd,
				value = cmdData.help or "No help."
			}
		end

		msg.channel:send(_msg)
	end,
	help = "Displays this."
}

-- command handling
local function call(callback, msg, args, line)
	local ok, err = xpcall(callback, function(err)
		local traceback = debug.traceback()
		print(err)
		print(traceback)
		coroutine.wrap(function()
			errorChat(msg.channel, { name = err, value = traceback }, "Command Error:")
		end)()
	end, msg, args, line)
end
client:on("messageCreate", function(msg)
	local text = msg.content
	local prefix = text:match(cmdPrefix)
	if prefix then
		local args = text:split(" ")
		local cmd = args[1]:sub(prefix:len() + 1)
		local line = text:sub(args[1]:len() + 2)
		args = parseArgs(line)

		for cmdName, cmdData in next, commands do
			if type(cmdName) == "table" then
				for _, cmdName in next, cmdName do
					if cmdName:lower() == cmd:lower() then
						call(cmdData.callback, msg, args, line)
					end
				end
			elseif cmdName:lower() == cmd:lower() then
				call(cmdData.callback, msg, args, line)
			end
		end
	end
end)

