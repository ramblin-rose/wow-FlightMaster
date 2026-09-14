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
	for i = 1, numRoutes do
		local line = AddOn:GetRouteLine(i)
		if line then
			AddOn:PerformRouteLineDraw(line, taxiNodeIndex, i, frame)
		end
	end
	local routeLines = AddOn.routeLines
	for i = numRoutes + 1, #routeLines do
		AddOn:GetRouteLine(i):Hide()
	end
end
--------------------------------
function AddOn:DrawOneHopLines()
	local numNodes = NumTaxiNodes()
	if numNodes > 0 then
		local numLines = 0
		local numSingleHops = 0
		local routeLines = AddOn.routeLines
		local nodeType, line

		for i = 1, numNodes do
			nodeType = TaxiNodeGetType(i)
			-- Stock Classic/TBC uses GetNumRoutes == 1; TaxiIsDirectFlight is later-only.
			if nodeType == "REACHABLE" and GetNumRoutes(i) == 1 then
				numSingleHops = numSingleHops + 1
				numLines = numLines + 1
				line = AddOn:GetRouteLine(numLines)
				if line then
					AddOn:PerformRouteLineDraw(line, i, 1, AddOn.frameRouteMap)
				end
			end
		end
		for i = numLines + 1, #routeLines do
			line = AddOn:GetRouteLine(i)
			line:Hide()
		end

		if numSingleHops == 0 then
			UIErrorsFrame:AddMessage(ERR_TAXINOPATHS, 1.0, 0.1, 0.1, 1.0)
		end
	end
end
