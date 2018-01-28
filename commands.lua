
-- argument parsing
local cmdPrefix = config.command_prefixes
if not config.command_prefixes or not config.command_prefixes[1] then
	local default = "d$"
	print('Command prefix not found, using default "' .. default .. '"')
	cmdPrefix = { default }
end
bot.commandPrefixes = cmdPrefix
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

function bot.errorMsg(channel, msg, title, footer, icon_url)
	local _msg = {
		embed = {
			title = title,
			description = isstring(msg) and msg or nil,
			fields = istable(msg) and { msg } or nil,
			color = 0xFF4040
		}
	}
	if _msg.embed.title then
		_msg.embed.title = ":interrobang: " .. _msg.embed.title
	else
		_msg.embed.description = ":interrobang: " .. _msg.embed.description
	end
	if footer then
		_msg.embed.footer = {
			icon_url = icon_url,
			text = footer
		}
	end
	channel:send(_msg)
end

bot.commands = {}
function bot.getCommands(cat)
	local tbl = {}
	if not cat then
		for cmd, cmdData in next, bot.commands do
			local cat = cmdData.category or "No Category"
			if not tbl[cat] then
				tbl[cat] = {}
			end
			if istable(cmd) then
				for _, name in next, cmd do
					cmdData.aliases = cmd
					tbl[cat][name] = cmdData
				end
			else
				tbl[cat][cmd] = cmdData
			end
		end
	elseif cat == true then
		for cmd, cmdData in next, bot.commands do
			if istable(cmd) then
				for _, name in next, cmd do
					cmdData.aliases = cmd
					tbl[name] = cmdData
				end
			else
				tbl[cmd] = cmdData
			end
		end
	else
		for cmd, cmdData in next, bot.commands do
			if cmdData.category and cmdData.category:lower() == cat:lower() then
				cat = cmdData.category -- preserve original case
				if istable(cmd) then
					for _, name in next, cmd do
						cmdData.aliases = cmd
						tbl[name] = cmdData
					end
				else
					tbl[cmd] = cmdData
				end
			end
		end
	end
	return tbl, cat
end
function bot.getCommand(cmd)
	return bot.getCommands(true)[cmd:lower()]
end

-- load commands
for file, _type in fs.scandirSync("./commands") do
	if _type ~= "directory" then
		require("./commands/" .. file)
	end
end
bot.getCommands() -- hahaa refresh .aliases.

-- command handling
local function call(cmdData, cmdName, msg, line, ...)
	_G.cmdError = function(err, footer, icon_url)
		local cmdName = cmdName
		coroutine.wrap(function() bot.errorMsg(msg.channel, err, cmdName .. " Error:", footer, icon_url) end)()
	end
	local _, ok, err, footer, icon_url = xpcall(cmdData.callback, function(err)
		local traceback = debug.traceback("Error while running " .. cmdName .. " command:", 2)
		print(err)
		print(traceback)
		coroutine.wrap(function()
			bot.errorMsg(msg.channel, { name = err:gsub(process.cwd() .. "/", ""), value = bot.errorToGithub(traceback) }, cmdName .. " Internal Error:")
		end)()
	end, msg, line, ...)
	if ok == false then
		bot.errorMsg(msg.channel, err, cmdName .. " Error:", footer, icon_url)
	end
end
client:on("messageCreate", function(msg)
	local text = msg.content
	local usedPrefix
	for _, prefix in next, cmdPrefix do
		if text:match("^" .. prefix:gsub("%$", "%%$")) then
			usedPrefix = prefix
			break
		end
	end
	if usedPrefix then
		local args = text:split(" ")
		local cmd = args[1]:sub(usedPrefix:len() + 1)
		local line = text:sub(args[1]:len() + 2):trim()
		args = parseArgs(line)

		for cmdName, cmdData in next, bot.commands do
			if istable(cmdName) then
				for _, cmdName in next, cmdName do
					if cmdName:lower() == cmd:lower() then
						msg.channel:broadcastTyping()
						if cmdData.ownerOnly and not config.owners[msg.author.id] then
							bot.errorMsg(msg.channel, "No access!", cmdName .. " Error:")
							return
						end
						bot.currentPrefix = usedPrefix
						call(cmdData, cmdName, msg, line, unpack(args))
						break
					end
				end
			elseif cmdName:lower() == cmd:lower() then
				msg.channel:broadcastTyping()
				if cmdData.ownerOnly and not config.owners[msg.author.id] then
					bot.errorMsg(msg.channel, "No access!", cmdName .. " Error:")
					return
				end
				bot.currentPrefix = usedPrefix
				call(cmdData, cmdName, msg, line, unpack(args))
			end
		end
	end
end)

