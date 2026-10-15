local AddOn = _G[select(1, ...)]
--------------------------------
function AddOn:CreateSyncState()
	return {
		started = false,
		digestTimer = nil,
		periodicTimer = nil,
		lastDigestWhisper = 0,
		peers = {},
		peerDigestPending = {},
		lastRumorAt = nil,
		lastRumorKind = nil,
		lastMismatch = nil,
		timeReplyQueue = {},
		pathReplyQueue = {},
		replyBusy = false,
		rumors = {},
		gossipTimer = nil,
		lastSend = 0,
		merkleDirty = true,
		timeRoot = nil,
		timeBuckets = nil,
		pathRoot = nil,
		pathBuckets = nil,
		inbound = {},
		channelId = nil,
		joinTimer = nil,
		joinAttempts = 0,
		loopback = false,
		playerName = nil,
	}
end
--------------------------------
function AddOn:EnsureSyncState()
	if type(self.sync) ~= "table" then
		self.sync = AddOn.CreateSyncState(self)
	end
	return self.sync
end
