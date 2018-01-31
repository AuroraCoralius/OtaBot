
local commands = bot.commands

local print = print
local function doEval(msg, func)
	local _msg = {}
	local ret = { pcall(func) }
	local ok = ret[1]
	table.remove(ret, 1)
	if not ok then return false, bot.errorToGithub(tostring(ret[1])) end
	if ret[1] then
		for k, v in next, ret do
			if not isstring(v) then
				local ok, res = pcall(inspect, v)
				if ok then
					ret[k] = res
				else
					ret[k] = tostring(v)
				end
			end
		end
		local res = "```lua\n" .. table.concat(ret, "\t") .. "```"
		if #res >= 2000 then
			res = res:sub(1, 1970) .. "```[...]\noutput truncated"
		end
		_msg.embed = {
			title = "Result:",
			description = res,
			color = 0x9B65BD
		}
	else
		_msg.content = ":white_check_mark:"
	end
	msg.channel:send(_msg)
end
commands[{"eval", "l"}] = { -- l command will be used for sandboxed Lua sometime though
	callback = function(msg, line)
		_G.self = client
		_G.msg = msg
		_G.print = function(...)
			local args = {...}
			local str = "```lua\n%s```"
			for k, v in next, args do
				args[k] = tostring(v):gsub("`", "\\`")
			end
			str = str:format(table.concat(args, "\t"))
			if #str >= 2000 then
				str = str:sub(1, 1970) .. "```[...]\noutput truncated"
			end
			msg.channel:send(str)
		end
		_G.whereis = function(func)
			msg.channel:send(bot.funcToGithub(func))
		end

		local ret = {}
		local func, err = loadstring("return " .. line, "eval")
		if type(func) == "function" then
			ret = { doEval(msg, func) }
		else
			local func, err = loadstring(line, "eval")
			if type(func) == "function" then
				ret = { doEval(msg, func) }
			end
		end

		_G.self = nil
		_G.msg = nil
		_G.print = print
		_G.whereis = nil

		return unpack(ret)
	end,
	help = {
		text = "Runs Lua in the bot's environment. Owner only.",
		example = "`{prefix}{cmd} function foo() return 1 end return foo()` will result into 1 being output by the bot."
	},
	ownerOnly = true,
	category = "Admin" -- "Lua"?
}
local function restart(msg, doUpdate)
	local out = doUpdate and io.popen("git pull"):read("*all") or nil
	msg.channel:send("```" .. (out and out .. "\n" or "") .. "Restarting..." .. "```")
	fs.writeFileSync("restart", "")
	process:exit() -- restart handled by shell script, I can't figure out any better way of doing this
end
commands.restart = {
	callback = function(msg)
		restart(msg, false)
	end,
	help = "Restarts the bot. Owner only.",
	ownerOnly = true,
	category = "Admin"
}
commands.update = {
	callback = function(msg)
		restart(msg, true)
	end,
	help = "Updates the bot from its git repository and restarts it. Owner only.",
	ownerOnly = true,
	category = "Admin"
}

local categoryIcons = { -- too lazy to find a better way
	Lua = "<:lua:399925204953989130>", -- might break if I ever remove the emote from tenrys.pw
	Utility = ":tools:",
	Admin = ":lock:",
	Colors = ":paintbrush:",
	Misc = ":gear:",
	Fun = ":tada:"
}
local function iconizeCategoryName(cat)
	if categoryIcons[cat] then
		return categoryIcons[cat] .. " " .. cat
	else
		return cat
	end
end
commands.help = {
	callback = function(msg, line, cmd)
		local cmdData
		if cmd then
			cmd = cmd:lower():trim()
			cmdData = bot.getCommand(cmd)
			catCmds, catName = bot.getCommands(cmd)
		end

		local _msg = {}
		local desc = "Supply a command or category name to get specific information."
		if not cmd then
			_msg = {
				embed = {
					title = ":information_source: Help: All Categories",
					description = desc,
					fields = {}
				}
			}

			local field = 1
			for catName, catCmds in next, bot.getCommands() do
				_msg.embed.fields[field] = { name = iconizeCategoryName(catName), value = "`" }
				local count = table.count(catCmds)
				local i = 0
				for cmd, cmdData in sortedPairs(catCmds) do
					if not cmdData.ownerOnly or (cmdData.ownerOnly and config.owners[msg.author.id]) then
						i = i + 1
						local desc = _msg.embed.fields[field].value
						local name = cmd
						desc = desc .. name .. (i == count and "" or ", ")
						_msg.embed.fields[field].value = desc
					end
				end

				if i == 0 then -- if no commands are available (example if you're not admin) then don't show the category
					_msg.embed.fields[field] = nil
					field = field - 1
				else
					_msg.embed.fields[field].value = _msg.embed.fields[field].value .. "`"
				end

				field = field + 1
			end
		elseif cmd:lower():trim() == "all" then
			_msg = {
				embed = {
					title = ":information_source: Help: All Commands",
					description = desc,
					fields = {
						{
							name = ":flashlight: Available commands:",
							value = "`",
						}
					}
				}
			}

			local count = table.count(bot.getCommands(true))
			local i = 0
			for cmd, cmdData in sortedPairs(bot.getCommands(true)) do
				if not cmdData.ownerOnly or (cmdData.ownerOnly and config.owners[msg.author.id]) then
					i = i + 1
					local desc = _msg.embed.fields[1].value
					local name = cmd
					desc = desc .. name .. (i == count and "" or ", ")
					_msg.embed.fields[1].value = desc
				end
			end
			_msg.embed.fields[1].value = _msg.embed.fields[1].value .. "`"
		elseif cmdData then
			local help = cmdData.help
			if istable(help) then
				help = table.copy(help) -- don't override actual command help
				local toReplace = { -- foreshadowing
					text = true,
					usage = true,
					example = true,
				}
				for name, text in next, help do
					if toReplace[name] then
						help[name] = text:gsub("{([^}.]+)}", function(field)
							if field == "prefix" then
								return bot.currentPrefix
							elseif field == "cmd" then
								return cmd
							end
						end)
					end
				end
			elseif not help then
				help = "No information provided."
			end
			_msg = {
				embed = {
					title = ":information_source: Command Help: " .. (cmdData.aliases and table.concat(cmdData.aliases, ", ") or cmd),
					description = istable(help) and help.text or help,
				}
			}
			if istable(help) then
				_msg.embed.fields = {}
				if help.usage then
					table.insert(_msg.embed.fields, {
						name = ":wrench: Usage",
						value = help.usage
					})
				end
				if help.example then
					table.insert(_msg.embed.fields, {
						name = ":bulb: Example",
						value = help.example
					})
				end
			end
		elseif catCmds and table.count(catCmds) > 0 then
			_msg = {
				embed = {
					title = ":information_source: Category Help: " .. iconizeCategoryName(catName),
					description = desc,
					fields = {
						{
							name = ":flashlight: Available commands:",
							value = "`",
						}
					}
				}
			}

			local count = table.count(bot.getCommands(cmd))
			local i = 0
			for cmd, cmdData in sortedPairs(bot.getCommands(cmd)) do
				if not cmdData.ownerOnly or (cmdData.ownerOnly and config.owners[msg.author.id]) then
					i = i + 1
					local desc = _msg.embed.fields[1].value
					local name = cmd
					desc = desc .. name .. (i == count and "" or ", ")
					_msg.embed.fields[1].value = desc
				end
			end
			_msg.embed.fields[1].value = _msg.embed.fields[1].value .. "`"
		else
			return false, "No such command / category!"
		end
		_msg.embed.color = 0x50ACFF

		msg.channel:send(_msg)
	end,
	help = {
		text = "Displays specific information about a command, or all commands available in a category.\nUse `{prefix}{cmd} all` to display all available commands in one go.",
		usage = "`{prefix}{cmd} <command / category name>`\n`{prefix}{cmd} all`",
		example = "`{prefix}{cmd} ping`\n`{prefix}{cmd} all`"
	},
	category = "Misc"
}
commands.prefixes = {
	callback = function(msg)
		local _msg = {
			embed = {
				title = ":flashlight: Available prefixes:",
				description = "`" .. table.concat(bot.commandPrefixes, ","):gsub("`", "\\`") .. "`",
				color = 0x50ACFF
			}
		}
		msg.channel:send(_msg)
	end,
	help = "Shows all prefixes the bot is willing to accept.",
	category = "Misc"
}
commands.ping = {
	callback = function(msg)
		local sent = msg.channel:send(":alarm_clock: Ping?")
		sent:setContent(":alarm_clock: Pong! Took `" .. math.ceil((sent.createdAt - msg.createdAt) * 10000) * 0.1 .. "ms`.")
	end,
	help = "Pings the bot.",
	category = "Misc"
}
commands.invite = {
	callback = function(msg)
		msg.channel:send(string.format([[
:robot: **Invite link**: <https://discordapp.com/oauth2/authorize?client_id=%s&scope=bot&permissions=268435456>
The `Manage Roles` permission is required for color roles. If you have no use for it, feel free to remove it.
]], client.user.id))
	end,
	help = "Posts the invite link for this bot.",
	category = "Utility",
}
commands.todo = {
	callback = function(msg)
		msg.channel:send("https://github.com/Re-Dream/dreambot_mk2/projects/1")
	end,
	ownerOnly = true,
	category = "Misc"
}
commands.setavatar = {
	callback = function(msg, line)
		line = line:trim()

		local use
		if line:match("^http://") then
			use = http
		elseif line:match("^https://") then
			use = https
		else
			return false, "Invalid protocol / URL!"
		end

		local body = ""
		use.get(line, function(res)
			res:on("data", function(chunk)
				body = body .. chunk
			end)
			res:on("end", function()
				fs.writeFileSync("avatar", body)
				client:setAvatar("avatar")
			end)
		end)
	end,
	ownerOnly = true,
	help = {
		text = "Changes the bot's avatar. Accepts URLs. HTTP / HTTPS only."
		usage = "`{prefix}{cmd} <url>`"
		example = "`{prefix}{cmd} http://example.com/image.png`"
	}
	category = "Admin"
}

