GemQuota = {}

local L = GemQuotaLocals

local gemCount = {}
local gemStats = {}
local metaGem = {status = "none", reqs = {}}

-- Base rating info
local ratings = {
	[L["Dodge Rating"]] = 12,
	[L["Parry Rating"]] = 15,
	[L["Defense Rating"]] = 1.5,
	[L["Hit Rating"]] = 1, --??
	[L["Crit Rating"]] = 1, --??
	[L["Haste Rating"]] = 1, --??
	[L["Resilience Rating"]] = 25,
}

-- One day, tabards will be socketable
local slots = {"HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot", "WristSlot",
		"TabardSlot", "HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot", "Finger0Slot", "Finger1Slot",
		"Trinket0Slot", "Trinket1Slot", "MainHandSlot", "SecondaryHandSlot", "RangedSlot", "AmmoSlot"}

function GemQuota:Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99Gem Quata|r: " .. msg)
end

function GemQuota:Enable()
	self.tooltip = CreateFrame("GameTooltip", "GemQuotaTooltip", self.frame, "GameTooltipTemplate")
	self.tooltip:SetOwner(self.frame, "ANCHOR_NONE")

	PLAYERSTAT_GEM_INFO = L["Gem Info"]
	table.insert(PLAYERSTAT_DROPDOWN_OPTIONS, "PLAYERSTAT_GEM_INFO")
	
	-- Defaults
	for _, color in pairs(L["COLORS"]) do
		table.insert(gemCount, {color = color, count = 0})
		gemStats[color] = {}
	end
	
	-- Rather do rescanning when the paper doll frame is shown
	-- because doing a rescan while we're in combat can be bad
	-- due to small lag
	PaperDollFrame:HookScript("OnShow", function()
		GemQuota.ScanEquip(GemQuota)
		GemQuota.UpdatePaperdollGems(GemQuota)

		GemQuota.frame:RegisterEvent("PLAYER_DAMAGE_DONE_MODS")
		GemQuota.frame:RegisterEvent("UNIT_STATS")
	end)
	
	PaperDollFrame:HookScript("OnHide", function()
		GemQuota.frame:UnregisterEvent("PLAYER_DAMAGE_DONE_MODS")
		GemQuota.frame:UnregisterEvent("UNIT_STATS")
	end)
end

local Orig_UpdatePaperdollStats = UpdatePaperdollStats
local rightSelection, leftSelection
function UpdatePaperdollStats(prefix, index, ...)
	Orig_UpdatePaperdollStats(prefix, index, ...)
	
	if( prefix == "PlayerStatFrameLeft" ) then
		leftSelection = index
	elseif( prefix == "PlayerStatFrameRight" ) then
		rightSelection = index
	end
	
	if( index == "PLAYERSTAT_MELEE_COMBAT" ) then
		if( leftSelection == prefix ) then
			getglobal("PlayerStatFrameLeft5"):Show()
		end

		if( rightSelection == prefix ) then
			getglobal("PlayerStatFrameRight5"):Show()
		end
	end
	
	if( index == "PLAYERSTAT_GEM_INFO" ) then
		GemQuota:UpdatePaperdollGems()
	end
end

function GemQuota:UpdatePaperdollGems()
	-- Don't update it if it's not our current selection
	if( ( not rightSelection and not leftSelection ) or ( rightSelection ~= "PLAYERSTAT_GEM_INFO" and leftSelection ~= "PLAYERSTAT_GEM_INFO" ) ) then
		return
	end

	local id = 1

	-- Meta gem status
	local row = getglobal("PlayerStatFrameRight" .. id)
	local label = getglobal("PlayerStatFrameRight" .. id .. "Label")
	local stat = getglobal("PlayerStatFrameRight" .. id .. "StatText")

	label:SetText(L["Meta"])
	stat:SetText(L[metaGem.status])
	
	if( metaGem.status ~= "none" ) then	
		row.tooltip = L["Requirements"]
	
		local reqs = ""
		for _, req in pairs(metaGem.reqs) do
			if( req.type == "more" ) then
				local moreCount = 0
				local thanCount = 0
				for _, gem in pairs(gemCount) do
					if( gem.color == req.more ) then
						moreCount = gem.count
					elseif( gem.color == req.than ) then
						thanCount = gem.count
					end
				end
				
				if( metaGem.status == "active" ) then
					reqs = reqs .. string.format(L["More %s than %s, have %d %s and %d %s."], req.more, req.than, moreCount, req.more, thanCount, req.than) .. "\n"
				else
					reqs = reqs .. string.format(L["More %s than %s, only have %d %s and %d %s."], req.more, req.than, moreCount, req.more, thanCount, req.than) .. "\n"
				end
			
			elseif( req.type == "least" or req.type == "exact" ) then
				local haveCount = 0
				for _, gem in pairs(gemCount) do
					if( gem.color == req.color ) then
						haveCount = gem.count
						break
					end
				end
				
				if( metaGem.status == "active" ) then
					if( req.type == "least" ) then
						reqs = reqs .. string.format(L["At least %d %s, have %d."], req.need, req.color, haveCount) .. "\n"
					else
						reqs = reqs .. string.format(L["Exactly %d %s, have %d."], req.need, req.color, haveCount) .. "\n"
					end
				else
					if( req.type == "least" ) then
						reqs = reqs .. string.format(L["At least %d %s, only have %d."], req.need, req.color, haveCount) .. "\n"
					else
						reqs = reqs .. string.format(L["Exactly %d %s, only have %d."], req.need, req.color, haveCount) .. "\n"
					end
				end
			end
		end
						
		row.tooltip2 = string.sub(reqs, 0, -3)
	
	-- No meta equipped
	else
		row.tooltip = L["Equipped Meta Gem"]
		row.tooltip2 = L["None"]
	end
	
	row.tooltip = HIGHLIGHT_FONT_COLOR_CODE .. row.tooltip .. FONT_COLOR_CODE_CLOSE
	row:Show()
	
	local playerLevel = UnitLevel("player")
	
	-- Now show total gem # and the tooltips for stats
	for _, gem in pairs(gemCount) do
		id = id + 1
		
		local row = getglobal("PlayerStatFrameRight" .. id)
		local label = getglobal("PlayerStatFrameRight" .. id .. "Label")
		local stat = getglobal("PlayerStatFrameRight" .. id .. "StatText")

		label:SetText(gem.color)
		stat:SetText(gem.count)

		row.tooltip = HIGHLIGHT_FONT_COLOR_CODE .. L["Total stats"] ..FONT_COLOR_CODE_CLOSE
		row:Show()
		
		-- Parse out the tooltip
		local list = {}
		for stat, total in pairs(gemStats[gem.color]) do
			-- Only show rating info if we're 60 or higher, not that it matters
			-- but just to be safe
			if( ratings[stat] and playerLevel >= 60 ) then
				local rating = 0
				if( playerLevel >= 70 ) then
					rating = total / (ratings[stat] * (playerLevel + 12) / 52)
				else
					rating = total / (ratings[stat] * 82 / (262 - 3 * playerLevel))
				end
				
				rating = string.format("%.2f%%", rating)
				if( stat == L["Resilience Rating"] ) then
					rating = "-" .. rating
				end
				
				table.insert(list, string.format("%s: %s (%s)", stat, GREEN_FONT_COLOR_CODE .. total .. FONT_COLOR_CODE_CLOSE, GREEN_FONT_COLOR_CODE .. rating .. FONT_COLOR_CODE_CLOSE))
			else
				table.insert(list, string.format("%s: %s", stat, GREEN_FONT_COLOR_CODE .. total .. FONT_COLOR_CODE_CLOSE))
			end
		end

		if( #(list) > 0 ) then
			row.tooltip2 = table.concat(list, "\n")
		elseif( gem.count > 0 ) then
			row.tooltip2 = L["No stats found"]
		else
			row.tooltip = nil
			row.tooltip2 = nil
		end
	end
	
	PlayerStatFrameRight5:Hide()
	PlayerStatFrameRight6:Hide()
end

function GemQuota:ParseMeta(...)
	metaGem.status = "active"
	for i=1, select("#", ...) do
		local text = string.trim((select(i, ...)))
		
		if( string.match(text, L["Requires more (.+) gems than (.+) gems"]) ) then
			local more, than = string.match(text, L["Requires more (.+) gems than (.+) gems"])
			table.insert(metaGem.reqs, {type = "more", more = more, than = than})
		
		elseif( string.match(text, L["Requires exactly ([0-9]+) (.+) gems"]) ) then
			local req, color = string.match(text, L["Requires exactly ([0-9]+) (.+) gems"])
			table.insert(metaGem.reqs, {type = "exact", need = req, color = color})

		elseif( string.match(text, L["Requires at least ([0-9]+) (.+) gems"]) ) then
			local req, color = string.match(text, L["Requires at least ([0-9]+) (.+) gems"])
			table.insert(metaGem.reqs, {type = "least", need = req, color = color})
		end

		-- Check for an inactive bonus
		if( string.match(text, "^|cff808080") ) then
			metaGem.status = "inactive"
		end
	end
end

function GemQuota:ScanGem(itemLink)
	-- We have to clear lines because if we scan the same link
	-- it'll close the tooltip instead and error
	self.tooltip:ClearLines()
	self.tooltip:SetHyperlink(itemLink)

	if( self.tooltip:NumLines() == 0 ) then
		return
	end
	
	local gemType = select(7, GetItemInfo(itemLink))
	
	-- Check if it's a meta gem
	if( gemType == L["Meta"] ) then
		self:ParseMeta(string.split("\n", getglobal("GemQuotaTooltipTextLeft" .. self.tooltip:NumLines() - 1):GetText()))
		return
	end
	
	-- Stats will always be the second to last row
	local text = string.lower(getglobal("GemQuotaTooltipTextLeft" .. self.tooltip:NumLines() - 1):GetText())
		
	-- Figure out stats
	local matchFound
	for color, tests in pairs(L["MATCHES"]) do
		local colorMatch
		for match, stat in pairs(tests) do
			if( string.match(text, match) ) then
				gemStats[color][stat] = (gemStats[color][stat] or 0) + tonumber(string.match(text, match))
				matchFound = true
				colorMatch = true
			end
		end
	end
	
	-- Just in-case a new format was added that breaks this
	if( not matchFound ) then
		self:Print(string.format(L["Failed to match %s no stats found. Please report the gem name to the comments at WoWInterface.com so this can be fixed."], itemLink))
		return
	end
		
	-- Increment gem total counts
	local gemTypes = getglobal("GemQuotaTooltipTextLeft" .. self.tooltip:NumLines()):GetText()
	for _, data in pairs(gemCount) do
		if( string.match(gemTypes, data.color) ) then
			data.count = data.count + 1
		end
	end
end

local function sortGems(a, b)
	if( not b ) then
		return false
	end
	
	if( a.count == b.count ) then
		return (a.color > b.color)
	end
	
	return (a.count > b.count)
end

function GemQuota:ScanEquip()
	-- Reset info
	metaGem.status = "none"
	
	for i=#(metaGem.reqs), 1, -1 do
		table.remove(metaGem.reqs, i)
	end
	
	for i=1, #(gemCount) do
		gemCount[i].count = 0
	end
	
	for _, data in pairs(gemStats) do
		for stat in pairs(data) do
			data[stat] = nil
		end
	end
	
	-- Scan inventory
	for _, slot in pairs(slots) do
		local itemLink = GetInventoryItemLink("player", GetInventorySlotInfo(slot))		
		if( itemLink ) then
			for i=1, 3 do
				local _, gemLink = GetItemGem(itemLink, i)
				if( gemLink ) then
					self:ScanGem(gemLink)
				end
			end
		end
	end

	table.sort(gemCount, sortGems)
end

GemQuota.frame = CreateFrame("Frame")
GemQuota.frame:RegisterEvent("ADDON_LOADED")
GemQuota.frame:SetScript("OnEvent", function(self, event, addon)
	if( event == "ADDON_LOADED" and addon == "GemQuota" ) then
		GemQuota.Enable(GemQuota)
	elseif( event == "PLAYER_DAMAGE_DONE_MODS" or event == "UNIT_STATS" ) then
		GemQuota.ScanEquip(GemQuota)
		GemQuota.UpdatePaperdollGems(GemQuota)
	end
end)
