

local emojis = {
	backArrow = '\226\172\133',
	fwdArrow = '\226\158\161',
	stop = '\226\143\185'
}

local paging = {
	pages = {},
	timeout = 60
}
function paging.init(resultsMsg, queryMsg, data, handler)
	paging.pages[resultsMsg.id] = {
		message = resultsMsg,
		query = queryMsg,
		author = queryMsg.author,
		data = data,
		handle = handler,
		endTime = os.time() + paging.timeout
	}
	resultsMsg:addReaction(emojis.backArrow)
	resultsMsg:addReaction(emojis.fwdArrow)
	resultsMsg:addReaction(emojis.stop)

	return paging.pages[queryMsg.id]
end

local function onReaction(reaction, userId)
	if userId == client.user.id then return end
	local page = paging.pages[reaction.message.id]
	if page and page.endTime > os.time() then
		-- if reaction.message.id ~= page.message.id then return end -- redundant
		if userId ~= page.author.id then return end

		local emoji = reaction.emojiName
		if emoji == emojis.backArrow or emoji == emojis.fwdArrow then
			local fwd = emoji == fwdArrow
			page:handle(fwd)
			page.endTime = os.time() + paging.timeout
		elseif emoji == emojis.stop then
			page.message:clearReactions()
			page.endTime = 0
			pages[reaction.message.id] = nil
		end
	end
end
timer.setInterval(1000, function()
	for msgId, page in next, paging.pages do
		if page.endTime < os.time() then
			coroutine.wrap(function()
				page.message:setContent("(:alarm_clock:)")
				page.message:clearReactions()
			end)()
			paging.pages[msgId] = nil
		end
	end
end)
client:on("reactionAdd", onReaction)
client:on("reactionRemove", onReaction)

return paging

