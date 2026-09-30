local AddOn = _G[select(1, ...)]
--------------------------------
function AddOn:InitRoute()
	AddOn.routeLines = {}
end
--------------------------------
function AddOn:GetRouteLine(lineIndex)
	local routeLines = AddOn.routeLines
	local line
	if lineIndex > #routeLines then
		line = AddOn.frameRouteMap:CreateTexture(nil, "BACKGROUND")
		line:SetTexture("Interface\\TaxiFrame\\UI-Taxi-Line")
		table.insert(routeLines, line)
	else
		line = routeLines[lineIndex]
	end
	return line
end
--------------------------------
function AddOn:HideRouteLines()
	local routeLines = AddOn.routeLines
	for i = 1, #routeLines do
		AddOn:GetRouteLine(i):Hide()
	end
end
--------------------------------
function AddOn:PerformRouteLineDraw(line, taxiNodeIndex, routeNodeIndex, frame)
	local taxiNodePositions = AddOn.taxiNodePositions
	local srcSlot = TaxiGetNodeSlot(taxiNodeIndex, routeNodeIndex, true)
	local dstSlot = TaxiGetNodeSlot(taxiNodeIndex, routeNodeIndex, false)
	local src = srcSlot and taxiNodePositions[srcSlot]
	local dst = dstSlot and taxiNodePositions[dstSlot]
	-- Last hop must end at the hovered destination even if TBC reports a
	-- waypoint slot that is not a flight master.
	if not dst and routeNodeIndex == GetNumRoutes(taxiNodeIndex) then
		dst = taxiNodePositions[taxiNodeIndex]
	end

	if src and dst then
		local w, h = AddOn:GetFrameDim(frame)
		local sx, sy = AddOn:GetPositionXY(src.position)
		local dx, dy = AddOn:GetPositionXY(dst.position)
		if sx and sy and dx and dy and w and h and w > 0 and h > 0 then
			DrawLine(line, frame, sx * w, (1.0 - sy) * h, dx * w, (1.0 - dy) * h, 32, TAXIROUTE_LINEFACTOR)
			line:Show()
		end
	end
end
--------------------------------
local function hopNodeIDs(taxiNodeIndex, routeNodeIndex)
	local srcSlot = TaxiGetNodeSlot(taxiNodeIndex, routeNodeIndex, true)
	local dstSlot = TaxiGetNodeSlot(taxiNodeIndex, routeNodeIndex, false)
	local numRoutes = GetNumRoutes(taxiNodeIndex)
	if (not dstSlot or dstSlot < 1) and routeNodeIndex == numRoutes then
		dstSlot = taxiNodeIndex
	end
	local originID
	if routeNodeIndex == 1 then
		originID = AddOn:GetOriginTaxiNodeID()
	end
	if not originID then
		originID = AddOn:GetTaxiNodeIDForSlot(srcSlot)
	end
	local destID
	if routeNodeIndex == numRoutes then
		destID = AddOn:GetTaxiNodeIDForSlot(taxiNodeIndex)
	end
	if not destID then
		destID = AddOn:GetTaxiNodeIDForSlot(dstSlot)
	end
	return originID, destID
end
--------------------------------
local function hideUnusedRouteLines(used)
	local routeLines = AddOn.routeLines
	for i = used + 1, #routeLines do
		AddOn:GetRouteLine(i):Hide()
	end
end
--------------------------------
local function drawHopOrSmooth(taxiNodeIndex, routeNodeIndex, frame, startIndex)
	if AddOn.DrawSmoothFlightPath then
		local originID, destID = hopNodeIDs(taxiNodeIndex, routeNodeIndex)
		local drawn = AddOn:DrawSmoothFlightPath(originID, destID, frame, startIndex)
		if drawn and drawn > 0 then
			return drawn
		end
	end
	local line = AddOn:GetRouteLine(startIndex)
	if line then
		AddOn:PerformRouteLineDraw(line, taxiNodeIndex, routeNodeIndex, frame)
	end
	return 1
end
--------------------------------
function AddOn:DrawHighlightedRoute(taxiNodeIndex)
	if not taxiNodeIndex or taxiNodeIndex < 1 or taxiNodeIndex > NumTaxiNodes() then
		return
	end
	if TaxiNodeGetType(taxiNodeIndex) ~= "REACHABLE" then
		return
	end

	local numRoutes = GetNumRoutes(taxiNodeIndex)
	if not numRoutes or numRoutes < 1 then
		return
	end

	local frame = AddOn.lineCanvas or AddOn.frameRouteMap
	AddOn:HideRouteLines()
	local used = 0
	if AddOn.DrawSmoothFlightPath then
		local originID = AddOn:GetOriginTaxiNodeID()
		local destID = AddOn:GetTaxiNodeIDForSlot(taxiNodeIndex)
		used = AddOn:DrawSmoothFlightPath(originID, destID, frame, 1) or 0
	end
	if used < 1 then
		for i = 1, numRoutes do
			used = used + drawHopOrSmooth(taxiNodeIndex, i, frame, used + 1)
		end
	end
	hideUnusedRouteLines(used)
end
--------------------------------
function AddOn:DrawOneHopLines()
	local numNodes = NumTaxiNodes()
	if numNodes > 0 then
		local numLines = 0
		local numSingleHops = 0
		local nodeType
		local originID = AddOn.GetOriginTaxiNodeID and AddOn:GetOriginTaxiNodeID()
		local frame = AddOn.frameRouteMap

		for i = 1, numNodes do
			nodeType = TaxiNodeGetType(i)
			-- Stock Classic/TBC uses GetNumRoutes == 1; TaxiIsDirectFlight is later-only.
			if nodeType == "REACHABLE" and GetNumRoutes(i) == 1 then
				numSingleHops = numSingleHops + 1
				local destID = AddOn.GetTaxiNodeIDForSlot and AddOn:GetTaxiNodeIDForSlot(i)
				local drawn = 0
				if originID and destID and AddOn.DrawSmoothFlightPath then
					drawn = AddOn:DrawSmoothFlightPath(originID, destID, frame, numLines + 1) or 0
				end
				if drawn < 1 then
					drawn = drawHopOrSmooth(i, 1, frame, numLines + 1)
				end
				numLines = numLines + drawn
			end
		end
		hideUnusedRouteLines(numLines)

		if numSingleHops == 0 then
			UIErrorsFrame:AddMessage(ERR_TAXINOPATHS, 1.0, 0.1, 0.1, 1.0)
		end
	end
end
