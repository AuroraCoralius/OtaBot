
local commands = bot.commands
local errorMsg = bot.errorMsg

local function doEval(msg, func)
	local _msg = {}
	local ret = { pcall(func) }
	local ok = ret[1]
	table.remove(ret, 1)
	if not ok then
		errorMsg(msg.channel, ret, "Lua Error:")
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
commands.eval = {
	callback = function(msg, args, line)
		if config.owners[msg.author.id] then
			_G.self = client
			_G.msg = msg
			local func, err = loadstring("return " .. line)
			if type(func) == "function" then
				doEval(msg, func)
			else
				local func, err = loadstring(line)
				if type(func) == "function" then
					doEval(msg, func)
				else
					errorMsg(msg.channel, err, "Lua Error:")
				end
			end
			_G.self = nil
			_G.msg = nil
		else
			errorMsg(msg.channel, "No access!")
		end
	end,
	help = {
		text = "Runs Lua. Owner only.",
		example = "`$eval function foo() return 1 end return foo()` will result into 1 being output by the bot."
	}
}
local function restart(msg, doUpdate)
	if config.owners[msg.author.id] then
		local out = doUpdate and io.popen("git pull"):read("*all") or nil
		msg.channel:send("```" .. (out and out .. "\n" or "") .. "Restarting..." .. "```")
		process:exit() -- restart handled by shell script, I can't figure out any better way of doing this
	else
		errorMsg(msg.channel, "No access!")
	end
end
commands.restart = {
	callback = function(msg)
		restart(msg, false)
	end,
	help = "Restarts the bot. Owner only."
}
commands.update = {
	callback = function(msg)
		restart(msg, true)
	end,
	help = "Updates the bot from its git repository and restarts it. Owner only."
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
			local i = 0
			local count = table.count(commands)
			for cmd, cmdData in next, commands do
				i = i + 1
				local desc = _msg.embed.fields[1].value
				local name = type(cmd) == "table" and ("{" .. table.concat(cmd, ", ") .. "}") or cmd
				desc = desc .. name .. (i == count and "" or ", ")
				_msg.embed.fields[1].value = desc
			end
			_msg.embed.fields[1].value = _msg.embed.fields[1].value .. "`"
		elseif cmdData then
			local help = cmdData.help
			if not help then
				help = "No information provided."
			end
			_msg = {
				embed = {
					title = "Help: " .. (cmdData.aliases and table.concat(cmdData.aliases, ", ") or cmd),
					description = type(help) == "table" and help.text or help,
				}
			}
			if type(help) == "table" then
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
		usage = "$help <command name>",
		example = "$help help"
	}
}

