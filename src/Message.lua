local AddOn = _G[select(1, ...)]

function AddOn:InitMessage()
	AddOn.messageHandler = {
		[AddOn.Message.ENABLE_ADDON] = AddOn.onEnableAddOn,
		[AddOn.Message.DISABLE_ADDON] = AddOn.onDisableAddOn,
	}
	
	AddOn:RegisterMessage(AddOn.Message.ENABLE_ADDON, function(...)
		AddOn:onMessage(...)
	end)

	AddOn:RegisterMessage(AddOn.Message.DISABLE_ADDON, function(...)
		AddOn:onMessage(...)
	end)
end

--------------------------------
function AddOn:onMessage(message, ...)
	local handler = AddOn.messageHandler[message]
	if type(handler) == "function" then
		handler(...)
	end
end
