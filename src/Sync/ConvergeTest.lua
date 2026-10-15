local AddOn = _G[select(1, ...)]
--------------------------------
local NODE_A, NODE_B, NODE_C, NODE_D = 900001, 900002, 900003, 900004
local MERKLE_WAIT = 4
local RUMOR_WAIT = 10

local busPeers = {}
local running
--------------------------------
local function fail(msg)
	error(msg, 2)
end
--------------------------------
local function after(delay, fn)
	AddOn.Timer:ScheduleTimer(fn, delay)
end
--------------------------------
local function bus(fromName, prefix, text, dist, target)
	for name, peer in pairs(busPeers) do
		if name ~= fromName then
			if dist ~= "WHISPER" or target == name then
				peer:OnFlightSyncComm(prefix, text, dist, fromName)
			end
		end
	end
end
--------------------------------
local function makePeer(name)
	local peer = {}
	setmetatable(peer, { __index = AddOn })
	peer.db = {
		faction = {},
		global = {
			shareFlightData = true,
			shareFlightPaths = true,
		},
	}
	peer.L = AddOn.L
	peer.Timer = AddOn.Timer
	peer.sync = AddOn:CreateSyncState()
	peer.sync.loopback = true
	peer.sync.playerName = name
	peer.SendCommMessage = function(_, prefix, text, dist, target)
		bus(name, prefix, text, dist, target)
	end
	function peer:GetSyncFaction()
		return "Alliance"
	end
	function peer:GetClientFamily()
		return peer.testFamily or AddOn.GetClientFamily(AddOn)
	end
	busPeers[name] = peer
	return peer
end
--------------------------------
local function stopPeer(peer)
	if peer and peer.StopFlightSync then
		peer:StopFlightSync()
	end
end
--------------------------------
local function clearBus()
	for name, peer in pairs(busPeers) do
		stopPeer(peer)
		busPeers[name] = nil
	end
end
--------------------------------
local function pathPoints(n)
	local pts = {}
	for i = 1, n do
		pts[i] = { x = i * 10, y = i * 20, instanceID = 530 }
	end
	return pts
end
--------------------------------
local function timeOf(peer, origin, dest)
	return peer:GetFlightTimeMeta(origin, dest)
end
--------------------------------
local function pathLen(peer, origin, dest)
	local samples = peer:GetFlightPathMeta(origin, dest)
	if samples then
		return #samples
	end
	return 0
end
--------------------------------
local function roots(peer)
	return select(1, peer:GetSyncTimeDigest()), select(1, peer:GetSyncPathDigest())
end
--------------------------------
local function meet(alice, bob)
	alice:StartFlightSync()
	bob:StartFlightSync()
	alice:WhisperSyncDigests("Bob")
	bob:WhisperSyncDigests("Alice")
end
--------------------------------
local function assertTimesEqual(alice, bob)
	local trA, prA = roots(alice)
	local trB, prB = roots(bob)
	if trA ~= trB then
		fail(string.format("time roots differ %s vs %s", tostring(trA), tostring(trB)))
	end
	if prA ~= prB then
		fail(string.format("path roots differ %s vs %s", tostring(prA), tostring(prB)))
	end
	alice:ForEachFlightTime(function(o, d, seconds, n)
		local bs, bn = timeOf(bob, o, d)
		if bs ~= seconds or bn ~= n then
			fail(string.format("time %d->%d alice=%s/%s bob=%s/%s", o, d, tostring(seconds), tostring(n), tostring(bs), tostring(bn)))
		end
	end)
	bob:ForEachFlightTime(function(o, d, seconds, n)
		local as, an = timeOf(alice, o, d)
		if as ~= seconds or an ~= n then
			fail(string.format("time %d->%d missing on alice", o, d))
		end
	end)
end
--------------------------------
local function assertPathsEqual(alice, bob)
	alice:ForEachFlightPath(function(o, d, samples, n)
		local bsamples, bn = bob:GetFlightPathMeta(o, d)
		if not bsamples or #bsamples ~= #samples or bn ~= n then
			fail(string.format("path %d->%d mismatch", o, d))
		end
	end)
	bob:ForEachFlightPath(function(o, d)
		if pathLen(alice, o, d) < 1 then
			fail(string.format("path %d->%d missing on alice", o, d))
		end
	end)
end
--------------------------------
local scenarios = {}

function scenarios.catchUp()
	local alice, bob = makePeer("Alice"), makePeer("Bob")
	alice:SetFlightTime(NODE_A, NODE_B, 120)
	alice:SetFlightTime(NODE_C, NODE_D, 45)
	alice:SetFlightPath(NODE_A, NODE_B, pathPoints(4))
	meet(alice, bob)
	return MERKLE_WAIT, function()
		assertTimesEqual(alice, bob)
		assertPathsEqual(alice, bob)
	end
end

function scenarios.union()
	local alice, bob = makePeer("Alice"), makePeer("Bob")
	alice:SetFlightTime(NODE_A, NODE_B, 90)
	bob:SetFlightTime(NODE_C, NODE_D, 30)
	meet(alice, bob)
	return MERKLE_WAIT, function()
		if timeOf(alice, NODE_C, NODE_D) ~= 30 then
			fail("alice missing bob hop")
		end
		if timeOf(bob, NODE_A, NODE_B) ~= 90 then
			fail("bob missing alice hop")
		end
		assertTimesEqual(alice, bob)
	end
end

function scenarios.timeNWins()
	local alice, bob = makePeer("Alice"), makePeer("Bob")
	alice:ApplySyncedFlightTime(NODE_A, NODE_B, 100, 1)
	bob:ApplySyncedFlightTime(NODE_A, NODE_B, 110, 3)
	meet(alice, bob)
	return MERKLE_WAIT, function()
		local s, n = timeOf(alice, NODE_A, NODE_B)
		if s ~= 110 or n ~= 3 then
			fail(string.format("alice expected 110/3 got %s/%s", tostring(s), tostring(n)))
		end
		s, n = timeOf(bob, NODE_A, NODE_B)
		if s ~= 110 or n ~= 3 then
			fail(string.format("bob expected 110/3 got %s/%s", tostring(s), tostring(n)))
		end
	end
end

function scenarios.pathLongerWins()
	local alice, bob = makePeer("Alice"), makePeer("Bob")
	alice:ApplySyncedFlightPath(NODE_A, NODE_B, pathPoints(4), 1)
	bob:ApplySyncedFlightPath(NODE_A, NODE_B, pathPoints(8), 1)
	meet(alice, bob)
	return MERKLE_WAIT, function()
		if pathLen(alice, NODE_A, NODE_B) ~= 8 then
			fail("alice did not take longer polyline")
		end
		if pathLen(bob, NODE_A, NODE_B) ~= 8 then
			fail("bob lost longer polyline")
		end
	end
end

function scenarios.sharePathsOff()
	local alice, bob = makePeer("Alice"), makePeer("Bob")
	bob.db.global.shareFlightPaths = false
	alice:SetFlightTime(NODE_A, NODE_B, 50)
	alice:SetFlightPath(NODE_A, NODE_B, pathPoints(4))
	meet(alice, bob)
	return MERKLE_WAIT, function()
		if timeOf(bob, NODE_A, NODE_B) ~= 50 then
			fail("bob did not take time")
		end
		if pathLen(bob, NODE_A, NODE_B) ~= 0 then
			fail("bob stored a path with sharing off")
		end
		if pathLen(alice, NODE_A, NODE_B) ~= 4 then
			fail("alice path changed")
		end
	end
end

function scenarios.eraMismatch()
	local alice, bob = makePeer("Alice"), makePeer("Bob")
	bob.testFamily = "classic-era"
	alice:SetFlightTime(NODE_A, NODE_B, 70)
	meet(alice, bob)
	return MERKLE_WAIT, function()
		if timeOf(bob, NODE_A, NODE_B) then
			fail("bob merged across era")
		end
		if timeOf(alice, NODE_A, NODE_B) ~= 70 then
			fail("alice time lost")
		end
	end
end

function scenarios.rumor()
	local alice, bob = makePeer("Alice"), makePeer("Bob")
	alice:StartFlightSync()
	bob:StartFlightSync()
	alice:SetFlightTime(NODE_A, NODE_B, 33)
	return RUMOR_WAIT, function()
		if timeOf(bob, NODE_A, NODE_B) ~= 33 then
			fail("bob did not receive rumor")
		end
	end
end
--------------------------------
local ORDER = {
	{ "catch-up", scenarios.catchUp },
	{ "union", scenarios.union },
	{ "time-n-wins", scenarios.timeNWins },
	{ "path-longer-wins", scenarios.pathLongerWins },
	{ "share-paths-off", scenarios.sharePathsOff },
	{ "era-mismatch", scenarios.eraMismatch },
	{ "rumor", scenarios.rumor },
}
--------------------------------
local function restoreLive()
	clearBus()
	running = false
	if AddOn.GetShareFlightData and AddOn:GetShareFlightData() then
		AddOn:StartFlightSync()
	end
end
--------------------------------
function AddOn:RunSyncConvergeTest()
	if running then
		self:Print("synctest already running")
		return
	end
	if UnitOnTaxi and UnitOnTaxi("player") then
		self:Print("synctest: not while on taxi")
		return
	end
	if self.GetFlightTimerState then
		local st = self:GetFlightTimerState()
		if st == "in_flight" or st == "takeoff" then
			self:Print("synctest: not while a flight timer is active")
			return
		end
	end
	running = true
	self:Print("synctest: starting (loopback Alice/Bob)")
	if self.StopFlightSync then
		self:StopFlightSync()
	end
	local i = 0
	local passed = 0
	local function step()
		clearBus()
		i = i + 1
		if i > #ORDER then
			self:Print(string.format("synctest: ALL PASS (%d)", passed))
			restoreLive()
			return
		end
		local name, fn = ORDER[i][1], ORDER[i][2]
		local ok, wait, check = pcall(fn)
		if not ok then
			self:Print("FAIL " .. name .. ": " .. tostring(wait))
			restoreLive()
			return
		end
		after(wait, function()
			local cok, err = pcall(check)
			if not cok then
				self:Print("FAIL " .. name .. ": " .. tostring(err))
				restoreLive()
				return
			end
			passed = passed + 1
			self:Print("PASS " .. name)
			step()
		end)
	end
	step()
end
