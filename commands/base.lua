
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
	help = "Runs Lua. [owner only]"
}
commands.update = {
	callback = function(msg)
		if config.owners[msg.author.id] then
			local out = io.popen("git pull"):read("*all")
			msg.channel:send(out .. "\nRestarting...")
			client:stop()
			client = nil
			local setfenv = _G.setfenv
			local __G = _G.__G
			_G = nil
			setfenv(1, __G)
			dofile("bot.lua") -- this is hacks
			-- process:exit()
		else
			errorMsg(msg.channel, "No access!")
		end
	end,
	help = "Updates the bot from its git repository and restarts it."
}
commands.help = {
	callback = function(msg, args, line)
		local _msg = {}
		local cmd = args[1]
		local cmdData
		if cmd then
			cmd = cmd:lower()
			cmdData = bot.getCommand(cmd)
		end
		if not cmd then
			_msg = {
				embed = {
					description = "Supply a command name to get specific information.",
					color = 0x9B65BD,
					fields = {
						{
							name = "Available commands:",
							value = "`",
						}
					},
					footer = {
						icon_url = client.user.avatarURL,
						text = "Help"
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
			_msg = {
				embed = {
					title = cmdData.aliases and table.concat(cmdData.aliases, ", ") or cmd,
					description = cmdData.help,
					color = 0x9B65BD,
					footer = {
						icon_url = client.user.avatarURL,
						text = "Help"
					}
				}
			}
		end

		msg.channel:send(_msg)
	end,
	help = "Displays this."
}

