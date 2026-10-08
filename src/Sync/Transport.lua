local AddOn = _G[select(1, ...)]
--------------------------------
local PREFIX = "FMSync"
local CHANNEL_NAME = "FlightMaster"
local JOIN_RETRY_MAX = 6
local JOIN_RETRY_DELAY = 2
local RATE_WINDOW = 10
local RATE_MAX = 30

local channelId
local joinTimer
local joinAttempts = 0
local inbound = {}
local commRegistered
--------------------------------
local function playerName()
	local name = UnitName("player")
	if Ambiguate then
		return Ambiguate(name, "none")
	end
	return name
end
--------------------------------
local function samePlayer(sender)
	if type(sender) ~= "string" or sender == "" then
		return true
	end
	local me = playerName()
	if Ambiguate then
		return Ambiguate(sender, "none") == me
	end
	return sender == me
end
--------------------------------
local function hideChannel()
	if not ChatFrame_RemoveChannel then
		return
	end
	for i = 1, (NUM_CHAT_WINDOWS or 10) do
		local frame = _G["ChatFrame" .. i]
		if frame then
			ChatFrame_RemoveChannel(frame, CHANNEL_NAME)
		end
	end
end
--------------------------------
local function resolveChannelId()
	local id = GetChannelName(CHANNEL_NAME)
	if type(id) == "number" and id > 0 then
		return id
	end
end
--------------------------------
local function tryJoinChannel()
	if JoinTemporaryChannel then
		JoinTemporaryChannel(CHANNEL_NAME)
	elseif JoinChannelByName then
		JoinChannelByName(CHANNEL_NAME)
	end
	local id = resolveChannelId()
	if id then
		channelId = id
		hideChannel()
		return true
	end
	return false
end
--------------------------------
local function stopJoinRetries()
	if joinTimer then
		AddOn.Timer:CancelTimer(joinTimer)
		joinTimer = nil
	end
end
--------------------------------
function AddOn:GetSyncPrefix()
	return PREFIX
end
--------------------------------
function AddOn:GetSyncChannelName()
	return CHANNEL_NAME
end
--------------------------------
function AddOn:GetSyncChannelId()
	if channelId and channelId > 0 then
		return channelId
	end
	channelId = resolveChannelId()
	return channelId
end
--------------------------------
function AddOn:JoinSyncChannel()
	stopJoinRetries()
	joinAttempts = 0
	if tryJoinChannel() then
		return true
	end
	joinTimer = AddOn.Timer:ScheduleRepeatingTimer(function()
		joinAttempts = joinAttempts + 1
		if tryJoinChannel() or joinAttempts >= JOIN_RETRY_MAX then
			stopJoinRetries()
		end
	end, JOIN_RETRY_DELAY)
	return false
end
--------------------------------
function AddOn:LeaveSyncChannel()
	stopJoinRetries()
	channelId = nil
	if LeaveChannelByName then
		LeaveChannelByName(CHANNEL_NAME)
	end
end
--------------------------------
local function rateOk(sender)
	local now = GetTime()
	local rec = inbound[sender]
	if not rec or now - rec.start >= RATE_WINDOW then
		inbound[sender] = { start = now, count = 1 }
		return true
	end
	rec.count = rec.count + 1
	return rec.count <= RATE_MAX
end
--------------------------------
function AddOn:SendSyncMessage(msg, distribution, target, prio, level)
	if type(msg) ~= "table" or type(distribution) ~= "string" then
		return false
	end
	local encoded = AddOn:SyncEncode(msg, level)
	if not encoded then
		return false
	end
	local allowMultipart = msg.t == "R" and msg.k == "p"
	if #encoded > AddOn:SyncMaxEncoded() and not allowMultipart then
		return false
	end
	AddOn:SendCommMessage(PREFIX, encoded, distribution, target, prio or "BULK")
	return true
end
--------------------------------
function AddOn:WhisperSyncMessage(msg, target, level)
	if type(target) ~= "string" or target == "" then
		return false
	end
	return AddOn:SendSyncMessage(msg, "WHISPER", target, "BULK", level)
end
--------------------------------
function AddOn:BroadcastSyncMessage(msg, level)
	local id = AddOn:GetSyncChannelId()
	if id then
		return AddOn:SendSyncMessage(msg, "CHANNEL", id, "BULK", level)
	end
	if IsInGuild and IsInGuild() then
		return AddOn:SendSyncMessage(msg, "GUILD", nil, "BULK", level)
	end
	local inRaid = (IsInRaid and IsInRaid()) or (GetNumRaidMembers and GetNumRaidMembers() > 0)
	local inGroup = (IsInGroup and IsInGroup()) or (GetNumPartyMembers and GetNumPartyMembers() > 0)
	if inRaid then
		return AddOn:SendSyncMessage(msg, "RAID", nil, "BULK", level)
	end
	if inGroup then
		return AddOn:SendSyncMessage(msg, "PARTY", nil, "BULK", level)
	end
	return false
end
--------------------------------
function AddOn:OnFlightSyncComm(prefix, text, distribution, sender)
	if prefix ~= PREFIX or type(text) ~= "string" then
		return
	end
	if samePlayer(sender) then
		return
	end
	if not AddOn:GetShareFlightData() then
		return
	end
	if Ambiguate then
		sender = Ambiguate(sender, "none")
	end
	if not rateOk(sender) then
		return
	end
	local msg = AddOn:SyncDecode(text)
	if not msg or msg.v ~= 1 then
		return
	end
	if msg.era ~= AddOn:GetClientFamily() then
		return
	end
	local faction = AddOn:GetSyncFaction()
	if not faction or msg.fac ~= faction then
		return
	end
	AddOn:HandleFlightSyncMessage(msg, distribution, sender)
end
--------------------------------
function AddOn:InitSyncTransport()
	if commRegistered then
		return
	end
	commRegistered = true
	AddOn:RegisterComm(PREFIX, "OnFlightSyncComm")
end
