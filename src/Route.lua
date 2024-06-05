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

	local src = taxiNodePositions[TaxiGetNodeSlot(taxiNodeIndex, routeNodeIndex, true)]
	local dst = taxiNodePositions[TaxiGetNodeSlot(taxiNodeIndex, routeNodeIndex, false)]

	if src and dst then
		local w, h = AddOn:GetFrameDim(frame)
		src = src.position
		dst = dst.position
		if src and dst then
			local sx, sy, dx, dy
			sx = src.x * w
			sy = (1.0 - src.y) * h
			dx = dst.x * w
			dy = (1.0 - dst.y) * h
			DrawLine(line, frame, sx, sy, dx, dy, 32, TAXIROUTE_LINEFACTOR)
			line:Show()
		end
	else
		if not dst then
			AddOn:Print("dst not found (route line)")
		end
		if not src then
			AddOn:Print("src not found (route line)")
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
			---@diagnostic disable-next-line: redundant-parameter
			if (nodeType == "REACHABLE") and TaxiIsDirectFlight(i) then
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
