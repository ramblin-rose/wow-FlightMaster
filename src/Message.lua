local AddOn = _G[select(1, ...)]
--------------------------------
function AddOn:InitMessage() end
--------------------------------
function AddOn:AddMessageHandler(message, fn)
	assert(type(fn) == "function")
	AddOn.messageHandler = AddOn.messageHandler or {}

	if not AddOn.messageHandler[message] then
		AddOn.messageHandler[message] = {}
	end

	AddOn.messageHandler[message][fn] = true

	AddOn:RegisterMessage(message, function(...)
		AddOn:onMessage(...)
	end)
end
--------------------------------
function AddOn:RemoveMessageHandler(message, fn)
	AddOn.messageHandler = AddOn.messageHandler or {}
	AddOn.messageHandler[message] = AddOn.messageHandler[message] or {}
	AddOn.messageHandler[message][fn] = nil
end
--------------------------------
function AddOn:onMessage(message, ...)
	if AddOn.messageHandler and AddOn.messageHandler[message] then
		for handler, _ in pairs(AddOn.messageHandler[message]) do
			handler(...)
		end
	end
end
