
local event = {
	listeners = {}
}

function event.addListener(name, id, callback)
	if not event.listeners[name] then event.listeners[name] = {} end
	event.listeners[name][id] = callback
end
function event.removeListener(name, id)
	if not event[name] then return end
	event.listeners[name][id] = nil
end

function event.emit(name, ...)
	if not event.listeners[name] then return end
	for id, callback in sortedPairs(event.listeners[name]) do
		callback(...)
	end
end

setmetatable(event, {
	__call = function(self, name, id, callback, ...)
		if not id then
			return self.listeners[name]
		elseif not callback then
			self.removeListener(name, id)
		else
			self.addListener(name, id, callback)
		end
	end
})

local events = require("./event_list.lua")
for _, name in next, events do
	client:on(name, function(...)
		event.emit(name, ...)
	end)
end

return event

