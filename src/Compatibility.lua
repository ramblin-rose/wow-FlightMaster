local AddOn = _G[select(1, ...)]

local function questieFlightMasterEnabled()
	local Questie = _G["Questie"]
	return Questie
		and Questie.db
		and Questie.db.profile
		and Questie.db.profile.townsfolkConfig
		and Questie.db.profile.townsfolkConfig["Flight Master"]
end

-- Questie's Flight Master option muddles this addon's POI pins on the World Map.
-- Notify user 3 times and then leave them be.
local function compatCheckQuestie()
	if questieFlightMasterEnabled() then
		if AddOn.db.global.compat.compatCheckQuestie > 0 then
			AddOn.db.global.compat.compatCheckQuestie = AddOn.db.global.compat.compatCheckQuestie - 1
			AddOn:Print(AddOn.L.compatQuestieFlightMaster)
		end
	end
end

function AddOn:InitCompatibility()
	AddOn.db.global.compat = AddOn.db.global.compat or { compatCheckQuestie = 3 }
	-- wait for some seconds before issuing this check.
	AddOn.Timer:ScheduleTimer(compatCheckQuestie, 7)
end
