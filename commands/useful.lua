
local commands = bot.commands
local errorMsg = bot.errorMsg

local emojis = {
	backArrow = '\226\172\133',
	forwardArrow = '\226\158\161',
	stop = '\226\143\185'
}
local animeChoice = 1
local pages = {}
local timeout = 60
local function animeToEmbed(data, choice)
	local _msg = {}

	local animes = data.anime:numChildren()
	local choice = math.clamp(choice, 1, animes) or 1
	local anime
	local multiple = data.anime.entry[2]
	if multiple then
		table.sort(data.anime.entry, function(a, b)
			return a.score:value() > b.score:value()
		end)
		anime = data.anime.entry[choice]
	else
		anime = data.anime.entry
	end

	-- Prepare for displaying data
	local title = anime.title:value()
	local id = anime.id:value()
	local _type = anime.type:value()
	local score = anime.score:value()
	local image = anime.image:value()
	local synopsis = anime.synopsis:value()
	if synopsis then
		synopsis = synopsis:gsub("<br%s?/>", "")
		synopsis = xml:FromXmlString(synopsis)
		synopsis = synopsis:gsub("&mdash;", "—")
		synopsis = synopsis:gsub("%[%w%](%w*)%[/%w%]", "%1") -- remove bbcode
		if #synopsis > 512 then
			synopsis = synopsis:sub(1, 512)
			synopsis = synopsis .. "[...]"
		end
		synopsis = "**Synopsis: **\n" .. synopsis
		local english = anime.english:value()
		if english then
			synopsis = "**English name:** " .. english .. "\n\n" .. synopsis
		end
	end
	local status = anime.status:value()
	local episodes = anime.episodes:value()
	episodes = (status:lower():match("airing") and tonumber(episodes) == 0) and "?" or episodes
	local startDate, endDate = anime.start_date:value(), anime.end_date:value()
	local isAiring = endDate == "0000-00-00"
	local airTime = isAiring and "Airing since " .. startDate or "Aired from " .. startDate .. " to " .. endDate

	_msg.embed = {
		title = title,
		description = synopsis,
		url = "http://myanimelist.net/anime/" .. id,
		fields = {
			{
				name = "Episodes - Status",
				value = episodes .. " - " .. status,
				inline = true
			},
			{
				name = "Type",
				value = _type,
				inline = true
			},
			{
				name = "Score",
				value = score,
				inline = true
			}
		},
		thumbnail = {
			url = image
		},
		color = 0xFF7FFF,
		footer = {
			icon_url = client.user.avatar_url,
			text = airTime .. " - MyAnimeList API"
		}
	}
	if multiple then
		_msg.embed.footer.text = "Page " .. choice .. "/" .. animes .. " - " .. _msg.embed.footer.text
	end

	return _msg, multiple
end
commands[{"anime", "mal"}] = {
	callback = function(msg, args, line)
		if not config.mal then errorMsg(msg.channel, "No MAL credentials.") return end
		if not xml then errorMsg(msg.channel, "No XML module.") return end

		local query = line
		if not query then errorMsg(msg.channel, "No search query provided.") return end

		local get = urlencode({
			q = query
		})

		local url = "https://myanimelist.net/api/anime/search.xml?" .. get
		local options = http.parseUrl(url)
		if not options.headers then options.headers = {} end
		options.headers["Authorization"] = "Basic " .. config.mal -- base64.decode(config.mal)
		local found = false
		local body = ""
		local req = https.get(options, function(res)
			res:on("data", function(chunk)
				body = body .. chunk
			end)
			res:on("end", function()
				local data = xml:ParseXmlText(body)
				if data.anime then
					animeChoice = 1
					local _msg, multiple = animeToEmbed(data, animeChoice)
					found = true
					coroutine.wrap(function()
						local newMsg = msg.channel:send(_msg) -- well this is ass.
						if multiple then
							newMsg:addReaction(emojis.backArrow)
							newMsg:addReaction(emojis.forwardArrow)
							newMsg:addReaction(emojis.stop)
							pages[newMsg.id] = {
								author  = msg.author,
								data    = data,
								animes  = data.anime:numChildren(),
								message = newMsg,
								endTime = os.time() + timeout
							}
						end
					end)()
				else
					coroutine.wrap(function()
						errorMsg(msg.channel, body, "MAL Error:", "MyAnimeList API")
					end)()
				end
			end)
		end)
		timer.setTimeout(5000, function()
			if found then return end

			coroutine.wrap(function()
				errorMsg(msg.channel, "No anime found.", "MAL Error:", "MyAnimeListAPI")
			end)()
		end)
	end,
	help = "Provides condensed information about an anime."
}
local function onReaction(reaction, userId)
	if userId == client.user.id then return end
	local page = pages[reaction.message.id]
	if page and page.endTime > os.time() then
		-- if reaction.message.id ~= page.message.id then return end
		if userId ~= page.author.id then return end

		local emoji = reaction.emojiName
		if emoji == emojis.backArrow or emoji == emojis.forwardArrow then
			local back = emoji == emojis.backArrow
			local oldChoice = animeChoice
			animeChoice = math.clamp(animeChoice + (back and -1 or 1), 1, page.animes)
			if oldChoice == animeChoice then return end

			local _msg = animeToEmbed(page.data, animeChoice)
			page.message:setEmbed(_msg.embed)
			page.endTime = os.time() + timeout
		elseif emoji == emojis.stop then
			page.message:clearReactions()
			page.endTime = 0
			pages[reaction.message.id] = nil
		end
	end
end
timer.setInterval(1000, function()
	for k, v in next, pages do
		if v.endTime < os.time() then
			coroutine.wrap(function()
				v.message:setContent("(:alarm_clock:)")
				v.message:clearReactions()
			end)()
			pages[k] = nil
		end
	end
end)
client:on("reactionAdd", onReaction)
client:on("reactionRemove", onReaction)

commands[{"translate", "tr", "тр"}] = {
	callback = function(msg, args, line)
		if not config.yandex_api then errorMsg("No Yandex API key provided.") return end

		local lang = args[2] and args[2]:lower() or "en"
		local get = urlencode({
			key = config.yandex_api,
			lang = lang,
			text = args[1]
		})

		local _msg = {}
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
							text = "Yandex Translate API"
						},
						color = 0x00FFC0
					}
				else
					errorMsg(msg.channel, data.message, "Translation Error:", "Yandex Translate API - code " .. data.code .. " - lang " .. lang)
				end
				coroutine.wrap(function()
					msg.channel:send(_msg) -- well this is ass.
				end)()
			end)
		end)
	end,
	help = "Translate stuff."
}

