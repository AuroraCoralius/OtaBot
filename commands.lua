
-- argument parsing
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

function bot.errorMsg(channel, msg, title, footer)
	local _msg = {
		embed = {
			title = title,
			description = type(msg) == "string" and msg or nil,
			fields = type(msg) == "table" and { msg } or nil,
			color = 0xFF4040
		}
	}
	if footerText then
		_msg.embed.footer = {
			icon_url = client.user.avatarURL,
			text = footer
		}
	end
	channel:send(_msg)
end

bot.commands = {}
function bot.getCommands()
	local tbl = {}
	for cmd, cmdData in next, bot.commands do
		if type(cmd) == "table" then
			for _, name in next, cmd do
				cmdData.aliases = cmd
				tbl[name] = cmdData
			end
		else
			tbl[cmd] = cmdData
		end
	end
	return tbl
end
function bot.getCommand(cmd)
	return bot.getCommands()[cmd:lower()]
end

-- load commands
for file, _type in fs.scandirSync("./commands") do
	if _type == "directory" then return end
	require("./commands/" .. file)
end

-- command handling
local function call(callback, msg, args, line)
	local ok, err = xpcall(callback, function(err)
		local traceback = debug.traceback()
		print(err)
		print(traceback)
		coroutine.wrap(function()
			bot.errorMsg(msg.channel, { name = err, value = traceback }, "Command Error:")
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

		for cmdName, cmdData in next, bot.commands do
			if type(cmdName) == "table" then
				for _, cmdName in next, cmdName do
					if cmdName:lower() == cmd:lower() then
						msg.channel:broadcastTyping()
						call(cmdData.callback, msg, args, line)
					end
				end
			elseif cmdName:lower() == cmd:lower() then
				msg.channel:broadcastTyping()
				call(cmdData.callback, msg, args, line)
			end
		end
	end
end)

