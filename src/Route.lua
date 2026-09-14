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
		src = src.position
		dst = dst.position
		local sx, sy, dx, dy
		if src and src.GetXY then
			sx, sy = src:GetXY()
		elseif src then
			sx, sy = src.x, src.y
		end
		if dst and dst.GetXY then
			dx, dy = dst:GetXY()
		elseif dst then
			dx, dy = dst.x, dst.y
		end
		if sx and sy and dx and dy then
			DrawLine(line, frame, sx * w, (1.0 - sy) * h, dx * w, (1.0 - dy) * h, 32, TAXIROUTE_LINEFACTOR)
			line:Show()
		end
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
