
local event = {
	listeners = {}
}

function event.addListener(evtName, name, callback)
	if not event.listeners[evtName] then event.listeners[evtName] = {} end
	event.listeners[evtName][name] = callback
end
function event.removeListener(evtName, name, callback)
	if not event[evtName] then return end
	event.listeners[evtName][name] = nil
end

function event.emit(evtName, ...)
	if not event.listeners[evtName] then return end
	for name, callback in sortedPairs(event.listeners[evtName]) do
		callback(...)
	end
end

setmetatable(event, {
	__call = function(self, evtName, name, callback, ...)
		if not name then
			return event.listeners[evtName]
		elseif not callback then
			event.removeListener(evtName, name)
		else
			event.addListener(evtName, name, callback)
		end
	end
})

local events = require("./event_list.lua")
for _, evtName in next, events do
	client:on(evtName, function(...)
		event.emit(evtName, ...)
	end)
end

return event

