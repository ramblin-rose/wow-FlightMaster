local AddOn = _G[select(1, ...)]
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
	local src, dst
	---@diagnostic disable-next-line: redundant-parameter
	src = taxiNodePositions[TaxiGetNodeSlot(taxiNodeIndex, routeNodeIndex, true)]
	---@diagnostic disable-next-line: redundant-parameter
	dst = taxiNodePositions[TaxiGetNodeSlot(taxiNodeIndex, routeNodeIndex, false)]
	if src and dst then
		DrawLine(line, AddOn.frameRouteMap, src.x, src.y, dst.x, dst.y, 32, TAXIROUTE_LINEFACTOR, AddOn.VIEWPORT_ORIGIN)
		line:Show()
	end
end
--------------------------------
function AddOn:DrawOneHopLines()
	if AddOn.mapInfo and AddOn.mapInfo.mapType == 2 then
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
				elseif nodeType == "DISTANT" then
					numSingleHops = numSingleHops + 1
					local button = AddOn.taxiButtons[i]
					button:Hide()
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
end
