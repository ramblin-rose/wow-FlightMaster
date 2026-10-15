local AddOn = _G[select(1, ...)]
--------------------------------
local PREFIX = "FMSync"
local CHANNEL_NAME = "FlightMaster"
local JOIN_RETRY_MAX = 6
local JOIN_RETRY_DELAY = 2
local RATE_WINDOW = 10
local RATE_MAX = 30

local commRegistered
--------------------------------
local function playerName(self)
	local s = self:EnsureSyncState()
	if type(s.playerName) == "string" and s.playerName ~= "" then
		return s.playerName
	end
	local name = UnitName("player")
	if Ambiguate then
		return Ambiguate(name, "none")
	end
	return name
end
--------------------------------
local function samePlayer(self, sender)
	if type(sender) ~= "string" or sender == "" then
		return true
	end
	local me = playerName(self)
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
local function tryJoinChannel(self)
	local s = self:EnsureSyncState()
	if JoinTemporaryChannel then
		JoinTemporaryChannel(CHANNEL_NAME)
	elseif JoinChannelByName then
		JoinChannelByName(CHANNEL_NAME)
	end
	local id = resolveChannelId()
	if id then
		s.channelId = id
		hideChannel()
		return true
	end
	return false
end
--------------------------------
local function stopJoinRetries(self)
	local s = self:EnsureSyncState()
	if s.joinTimer then
		(self.Timer or AddOn.Timer):CancelTimer(s.joinTimer)
		s.joinTimer = nil
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
	local s = self:EnsureSyncState()
	if s.loopback then
		return s.channelId or 1
	end
	if s.channelId and s.channelId > 0 then
		return s.channelId
	end
	s.channelId = resolveChannelId()
	return s.channelId
end
--------------------------------
function AddOn:JoinSyncChannel()
	local s = self:EnsureSyncState()
	if s.loopback then
		s.channelId = 1
		return true
	end
	stopJoinRetries(self)
	s.joinAttempts = 0
	if tryJoinChannel(self) then
		return true
	end
	s.joinTimer = (self.Timer or AddOn.Timer):ScheduleRepeatingTimer(function()
		s.joinAttempts = (s.joinAttempts or 0) + 1
		if tryJoinChannel(self) or s.joinAttempts >= JOIN_RETRY_MAX then
			stopJoinRetries(self)
		end
	end, JOIN_RETRY_DELAY)
	return false
end
--------------------------------
function AddOn:LeaveSyncChannel()
	local s = self:EnsureSyncState()
	stopJoinRetries(self)
	s.channelId = nil
	if s.loopback then
		return
	end
	if LeaveChannelByName then
		LeaveChannelByName(CHANNEL_NAME)
	end
end
--------------------------------
local function rateOk(self, sender)
	local s = self:EnsureSyncState()
	local now = GetTime()
	local rec = s.inbound[sender]
	if not rec or now - rec.start >= RATE_WINDOW then
		s.inbound[sender] = { start = now, count = 1 }
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
	local encoded = self:SyncEncode(msg, level)
	if not encoded then
		return false
	end
	local allowMultipart = msg.t == "R" and msg.k == "p"
	if #encoded > self:SyncMaxEncoded() and not allowMultipart then
		return false
	end
	self:SendCommMessage(PREFIX, encoded, distribution, target, prio or "BULK")
	return true
end
--------------------------------
function AddOn:WhisperSyncMessage(msg, target, level)
	if type(target) ~= "string" or target == "" then
		return false
	end
	return self:SendSyncMessage(msg, "WHISPER", target, "BULK", level)
end
--------------------------------
function AddOn:BroadcastSyncMessage(msg, level)
	local s = self:EnsureSyncState()
	if s.loopback then
		return self:SendSyncMessage(msg, "CHANNEL", s.playerName or "loopback", "BULK", level)
	end
	local id = self:GetSyncChannelId()
	if id then
		return self:SendSyncMessage(msg, "CHANNEL", id, "BULK", level)
	end
	if IsInGuild and IsInGuild() then
		return self:SendSyncMessage(msg, "GUILD", nil, "BULK", level)
	end
	local inRaid = (IsInRaid and IsInRaid()) or (GetNumRaidMembers and GetNumRaidMembers() > 0)
	local inGroup = (IsInGroup and IsInGroup()) or (GetNumPartyMembers and GetNumPartyMembers() > 0)
	if inRaid then
		return self:SendSyncMessage(msg, "RAID", nil, "BULK", level)
	end
	if inGroup then
		return self:SendSyncMessage(msg, "PARTY", nil, "BULK", level)
	end
	return false
end
--------------------------------
function AddOn:OnFlightSyncComm(prefix, text, distribution, sender)
	if prefix ~= PREFIX or type(text) ~= "string" then
		return
	end
	if samePlayer(self, sender) then
		return
	end
	if not self:GetShareFlightData() then
		return
	end
	if Ambiguate then
		sender = Ambiguate(sender, "none")
	end
	if not rateOk(self, sender) then
		return
	end
	local msg = self:SyncDecode(text)
	if not msg or msg.v ~= 1 then
		return
	end
	if msg.era ~= self:GetClientFamily() then
		return
	end
	local faction = self:GetSyncFaction()
	if not faction or msg.fac ~= faction then
		return
	end
	self:HandleFlightSyncMessage(msg, distribution, sender)
end
--------------------------------
function AddOn:InitSyncTransport()
	if commRegistered then
		return
	end
	commRegistered = true
	self:RegisterComm(PREFIX, "OnFlightSyncComm")
end
