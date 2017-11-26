
local commands = bot.commands
local errorMsg = bot.errorMsg

local function doEval(msg, func)
	local _msg = {}
	local ret = { pcall(func) }
	local ok = ret[1]
	table.remove(ret, 1)
	if not ok then
		errorMsg(msg.channel, bot.errorToGithub(tostring(ret[1])), "Lua Error:")
		return
	end
	if ret[1] then
		for k, v in next, ret do
			ret[k] = tostring(v)
		end
		_msg.embed = {
			title = "Result:",
			description = "```lua\n" .. table.concat(ret, "\t") .. "\n```",
			color = 0x9B65BD
		}
	else
		_msg.content = ":white_check_mark:"
	end
	msg.channel:send(_msg)
end
local print = print
commands[{"eval", "l"}] = { -- l command will be used for sandboxed Lua sometime though
	callback = function(msg, args, line)
		_G.self = client
		_G.msg = msg
		_G.print = function(...)
			local args = {...}
			local str = #args > 1 and "```%s```" or "%s"
			for k, v in next, args do
				args[k] = tostring(v):gsub("`", "\\`")
			end
			str = str:format(table.concat(args, "\t"))
			msg.channel:send(str)
		end
		local func, err = loadstring("return " .. line, "eval")
		if type(func) == "function" then
			doEval(msg, func)
		else
			local func, err = loadstring(line, "eval")
			if type(func) == "function" then
				doEval(msg, func)
			else
				errorMsg(msg.channel, bot.errorToGithub(tostring(err)), "Lua Error:")
			end
		end
		_G.self = nil
		_G.msg = nil
		_G.print = print
	end,
	help = {
		text = "Runs Lua in the bot's environment. Owner only.",
		example = "`{prefix}eval function foo() return 1 end return foo()` will result into 1 being output by the bot."
	},
	ownerOnly = true
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
	ownerOnly = true
}
commands.update = {
	callback = function(msg)
		restart(msg, true)
	end,
	help = "Updates the bot from its git repository and restarts it. Owner only.",
	ownerOnly = true
}
commands.help = {
	callback = function(msg, args, line)
		local cmd = args[1]
		local cmdData
		if cmd then
			cmd = cmd:lower()
			cmdData = bot.getCommand(cmd)
		end

		local _msg = {}
		if not cmd then
			_msg = {
				embed = {
					title = "Help",
					description = "Supply a command name to get specific information.",
					fields = {
						{
							name = "Available commands:",
							value = "`",
						}
					}
				}
			}

			local count = table.count(bot.getCommands())
			local printed = {}
			local i = 0
			for cmd, cmdData in sortedPairs(bot.getCommands()) do
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
				local toReplace = { -- foreshadowing
					text = true,
					usage = true,
					example = true,
				}
				for name, text in next, help do
					if toReplace[name] then
						help[name] = text:gsub("{prefix}", bot.currentPrefix)
					end
				end
			elseif not help then
				help = "No information provided."
			end
			_msg = {
				embed = {
					title = "Help: " .. (cmdData.aliases and table.concat(cmdData.aliases, ", ") or cmd),
					description = istable(help) and help.text or help,
				}
			}
			if istable(help) then
				_msg.embed.fields = {}
				if help.usage then
					table.insert(_msg.embed.fields, {
						name = "Usage",
						value = help.usage
					})
				end
				if help.example then
					table.insert(_msg.embed.fields, {
						name = "Example",
						value = help.example
					})
				end
			end
		else
			errorMsg(msg.channel, "No such command!", "Help")
			return
		end
		_msg.embed.color = 0x50ACFF

		msg.channel:send(_msg)
	end,
	help = {
		text = "Displays this.",
		usage = "`{prefix}help <command name>`",
		example = "`{prefix}help ping`"
	}
}
commands.prefixes = {
	callback = function(msg)
		local _msg = {
			embed = {
				title = "Available prefixes:",
				description = "`" .. table.concat(bot.commandPrefixes, ","):gsub("`", "\\`") .. "`",
				color = 0x50ACFF
			}
		}
		msg.channel:send(_msg)
	end,
	help = "Shows all prefixes the bot is willing to accept."
}
commands.ping = {
	callback = function(msg)
		local sent = msg.channel:send(":alarm_clock: Ping?")
		sent:setContent(":alarm_clock: Pong! Took `" .. math.ceil((sent.createdAt - msg.createdAt) * 100) .."ms`.")
	end,
	help = "Pings the bot."
}

