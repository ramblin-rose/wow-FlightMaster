local AddOn = _G[select(1, ...)]
local L = AddOn.L

function AddOn:InitConfig()
	local options = {
		name = AddOn.String.CommandName,
		handler = self,
		type = "group",
		args = {
			[L.on] = {
				name = L.on,
				desc = ENABLE .. " " .. AddOn.String.Title,
				type = "input",
				set = function()
					AddOn:SendMessage(AddOn.Message.ENABLE_ADDON)
					AddOn:Print(READY)
					AddOn:SetEnabled(true)
				end,
			},
			[L.off] = {
				name = L.off,
				desc = DISABLE .. " " .. AddOn.String.Title,
				type = "input",
				set = function()
					AddOn:SendMessage(AddOn.Message.DISABLE_ADDON)
					AddOn:Print(ADDON_DISABLED)
					AddOn:SetEnabled(false)
				end,
			},
		},
	}
	LibStub("AceConfig-3.0"):RegisterOptionsTable(tostring(self), options, AddOn.String.CommandName)

	AddOn.db = LibStub("AceDB-3.0"):New(AddOn.name .. "DB", {
		global = {},
	})
	-- correct the lack of serialization versioning
	if AddOn.db.global.version == nil then		
		AddOn.db.global.version = 1
	end
end
--------------------------------
function AddOn:SetEnabled(enable)
	AddOn.enabled = enable
end
--------------------------------
function AddOn:GetEnabled()
	return AddOn.enabled
end
