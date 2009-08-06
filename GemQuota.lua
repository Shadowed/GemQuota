GemQuota = {}

local L = GemQuotaLocals
local leftSelection, rightSelection
local gemCount, gemStats, metaGem = {}, {}, {status = "none", reqs = {}}

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
	
	GemQuotaDB = GemQuotaDB or {reported = {}}
	
	-- Defaults
	for _, color in pairs(L.colors) do
		table.insert(gemCount, {color = color, count = 0})
		gemStats[color] = {}
	end
		
	-- Rather do rescanning when the paper doll frame is shown
	-- because doing a rescan while we're in combat can be bad
	-- due to small lag
	PaperDollFrame:HookScript("OnShow", function()
		if( InCombatLockdown() ) then
			GemQuota.frame:RegisterEvent("PLAYER_REGEN_ENABLED")
			return
		end
		
		GemQuota:Update()
	end)
	
	PaperDollFrame:HookScript("OnHide", function()
		GemQuota.frame:UnregisterEvent("PLAYER_DAMAGE_DONE_MODS")
		GemQuota.frame:UnregisterEvent("UNIT_STATS")
	end)
	
	-- Update it with our custom selection
	local Orig_UpdatePaperdollStats = UpdatePaperdollStats
	UpdatePaperdollStats = function(...)
		Orig_UpdatePaperdollStats(...)

		if( GetCVar("playerStatLeftDropdown") == "PLAYERSTAT_MELEE_COMBAT" ) then
			getglobal("PlayerStatFrameLeft5"):Show()
		end

		if( GetCVar("playerStatRightDropdown") == "PLAYERSTAT_MELEE_COMBAT" ) then
			getglobal("PlayerStatFrameRight5"):Show()
		end
		
		GemQuota:UpdatePaperdollGems()
	end

	-- Make sure we do an update if it was loaded via AddonLoader
	if( PaperDollFrame:IsVisible() ) then
		self:Update()
		
		-- Do a text update too if we had one of them selected
		if( GetCVar("playerStatLeftDropdown") == "PLAYERSTAT_GEM_INFO" ) then
			UIDropDownMenu_SetText(PlayerStatFrameLeftDropDown, L["Gem Info"])
		end
		
		if( GetCVar("playerStatRightDropdown") == "PLAYERSTAT_GEM_INFO" ) then
			UIDropDownMenu_SetText(PlayerStatFrameRightDropDown, L["Gem Info"])
		end
	end
end

function GemQuota:Update()
	self:ScanEquip()
	self:UpdatePaperdollGems()

	self.frame:RegisterEvent("PLAYER_DAMAGE_DONE_MODS")
	self.frame:RegisterEvent("UNIT_STATS")
end

function GemQuota:UpdatePaperdollGems()
	if( GetCVar("playerStatLeftDropdown") ~= "PLAYERSTAT_GEM_INFO" and GetCVar("playerStatRightDropdown") ~= "PLAYERSTAT_GEM_INFO" ) then
		return
	end

	local id = 1

	-- Meta gem status
	local row = getglobal("PlayerStatFrameRight" .. id)
	local label = getglobal("PlayerStatFrameRight" .. id .. "Label")
	local stat = getglobal("PlayerStatFrameRight" .. id .. "StatText")

	label:SetText(L["Meta"])
	stat:SetText(L.status[metaGem.status])
	
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
			table.insert(list, string.format("%s: %s", stat, GREEN_FONT_COLOR_CODE .. total .. FONT_COLOR_CODE_CLOSE))
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

	PlayerStatFrameRight6:Hide()
end

function GemQuota:ParseMeta(...)
	metaGem.status = "active"
	for i=1, select("#", ...) do
		local text = string.trim((select(i, ...)))

		if( string.match(text, L["Requires more (.+) gems than (.+) gem"]) ) then
			local more, than = string.match(text, L["Requires more (.+) gems than (.+) gem"])
			table.insert(metaGem.reqs, {type = "more", more = more, than = than})
		
		elseif( string.match(text, L["Requires exactly ([0-9]+) (.+) gem"]) ) then
			local req, color = string.match(text, L["Requires exactly ([0-9]+) (.+) gem"])
			table.insert(metaGem.reqs, {type = "exact", need = req, color = color})

		elseif( string.match(text, L["Requires at least ([0-9]+) (.+) gem"]) ) then
			local req, color = string.match(text, L["Requires at least ([0-9]+) (.+) gem"])
			table.insert(metaGem.reqs, {type = "least", need = req, color = color})
		end
			
		-- Check for an inactive bonus
		if( string.match(text, "^|cff808080") ) then
			metaGem.status = "inactive"
		end
	end
end

--/script GemQuota:ScanGem((select(2, GetItemInfo(42142))))
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
		self:ParseMeta(string.split("\n", getglobal("GemQuotaTooltipTextLeft" .. self.tooltip:NumLines() - 2):GetText()))
		return
	end
	
	local offset = isDragons and 3 or 2
	local text = string.lower(getglobal("GemQuotaTooltipTextLeft" .. self.tooltip:NumLines() - offset):GetText())
		
	-- Figure out stats
	local matchFound
	for color, tests in pairs(L.patterns) do
		for match, stat in pairs(tests) do
			if( string.match(text, match) ) then
				-- Instead of splitting off the stats we find from the Dragon's Eye into it's "real" color
				-- we will move it into the Prismatic category regardless
				if( isDragons ) then
					color = "Prismatic"
				end
				
				gemStats[color][stat] = (gemStats[color][stat] or 0) + tonumber(string.match(text, match))
				matchFound = true
			end
		end
	end
	
	-- Just in-case a new format was added that breaks this
	if( not matchFound ) then
		if( not GemQuotaDB.reported[itemLink] ) then
			GemQuotaDB.reported[itemLink] = true
			self:Print(string.format(L["Failed to match %s no stats found. Please report the gem name to the comments at WoWInterface.com so this can be fixed."], itemLink))
		end
		return
	end

	GemQuotaDB.reported[itemLink] = nil
	
	-- Increment the Prismatic count, not the main type
	if( gemType == L["Prismatic"] ) then
		for _, data in pairs(gemCount) do
			if( data.color == L["Prismatic"] ) then
				data.count = data.count + 1
			end
		end
		return
	end
		
	-- Increment gem total counts
	local gemTypes = getglobal("GemQuotaTooltipTextLeft" .. self.tooltip:NumLines() - 1):GetText()
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
		GemQuota:Enable()
	elseif( event == "PLAYER_REGEN_ENABLED" ) then
		GemQuota.frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
		GemQuota:ScanEquip()
		GemQuota:UpdatePaperdollGems()
	elseif( event == "PLAYER_DAMAGE_DONE_MODS" or ( event == "UNIT_STATS" and addon == "player" ) ) then
		GemQuota:ScanEquip()
		GemQuota:UpdatePaperdollGems()
	end
end)
