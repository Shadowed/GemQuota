GemCount = {}

local frame
local L = GemCountLocals

local ColorByLocal = {}
local GemTotals = {}
local GemByName = {}
local GemStats = {}

local MetaGem = { status = "none", reqs = {} }

-- One day, tabards will be socketable
local slots = { "HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot", "WristSlot",
		"TabardSlot", "HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot", "Finger0Slot", "Finger1Slot",
		"Trinket0Slot", "Trinket1Slot", "MainHandSlot", "SecondaryHandSlot", "RangedSlot", "AmmoSlot" }

function GemCount:Enable()
	self.tooltip = CreateFrame( "GameTooltip", "GemCountTooltip", UIParent, "GameTooltipTemplate" )
	self.tooltip:SetOwner( this, "ANCHOR_NONE" )

	PLAYERSTAT_GEM_COUNT = L["Gem Count"]
	table.insert( PLAYERSTAT_DROPDOWN_OPTIONS, "PLAYERSTAT_GEM_COUNT" )
	
	-- Add the basic gem colors
	for colorToken, color in pairs( L["TYPES"] ) do
		table.insert( GemTotals, { color = colorToken, count = 0 } ) 
		
		ColorByLocal[ color ] = colorToken
		GemByName[ colorToken ] = 0
		GemStats[ colorToken ] = {}
	end
	
	-- Hook everything
	hooksecurefunc( "UpdatePaperdollStats", self.UpdatePaperdollStats )

	-- Rather do rescanning when the paper doll frame is shown
	-- because doing a rescan while we're in combat can be bad
	-- due to small lag
	PaperDollFrame:HookScript("OnShow", function()
		GemCount.ScanItems(GemCount)
		GemCount.UpdatePaperdollGems(GemCount)

		frame:RegisterEvent("PLAYER_DAMAGE_DONE_MODS")
		frame:RegisterEvent("UNIT_STATS")
	end)
	
	PaperDollFrame:HookScript("OnHide", function()
		GemCount:UnregisterEvent("PLAYER_DAMAGE_DONE_MODS")
		GemCount:UnregisterEvent("UNIT_STATS")
	end)
end

function GemCount:WrapColor( color, text )
	if( color == "Red" ) then
		return RED_FONT_COLOR_CODE .. text .. FONT_COLOR_CODE_CLOSE
	elseif( color == "Blue" ) then
		return "|cff0070dd" .. text .. FONT_COLOR_CODE_CLOSE
	elseif( color == "Yellow" ) then
		return "|cffffff00" .. text .. FONT_COLOR_CODE_CLOSE
	elseif( color == "Prismatic" ) then
		return "|cffffffff" .. text .. FONT_COLOR_CODE_CLOSE
	end
	
	return text
end

function GemCount:UpdatePaperdollGems()
	-- Don't update it if it's not our current selection
	if( ( not PLAYERSTAT_RIGHTDROPDOWN_SELECTION and not PLAYERSTAT_LEFTDROPDOWN_SELECTION ) or ( PLAYERSTAT_RIGHTDROPDOWN_SELECTION ~= "PLAYERSTAT_GEM_COUNT" and PLAYERSTAT_LEFTDROPDOWN_SELECTION ~= "PLAYERSTAT_GEM_COUNT" ) ) then
		return
	end

	local i = 1
	local row, label, stat

	-- Meta gem status
	row = getglobal( "PlayerStatFrameRight" .. i )
	label = getglobal( row:GetName() .. "Label" )
	stat = getglobal( row:GetName() .. "StatText" )

	label:SetText( L["Meta"] )
	stat:SetText( L[ MetaGem.status ] )

	if( MetaGem.status == "active" ) then
		row.tooltip = L["Equipped Meta Gem"]
		row.tooltip2 = L["Currently active"]
	elseif( MetaGem.status == "inactive" ) then
		row.tooltip = L["Requirements"]
		
		local list = {}
		
		-- Alright, find out what we need to activate it still
		for _, req in pairs( MetaGem.reqs ) do
			if( req.type == "more" ) then
				table.insert( list, string.format( L["More %s (%s) then %s (%s)"], self:WrapColor( req.moreColor, L["TYPES"][ req.moreColor ] ), GemByName[ req.moreColor ], self:WrapColor( req.thenColor, L["TYPES"][ req.thenColor ] ), GemByName[ req.thenColor ] ) )
			elseif( req.type == "least" ) then
				table.insert( list, string.format( L["At least %d (%s) %s"], req.count, GemByName[ req.color ], self:WrapColor( req.color, L["TYPES"][ req.color ] ) ) )
			end
		end
		
		row.tooltip2 = table.concat( list, "\n" )
	else
		row.tooltip = L["Equipped Meta Gem"]
		row.tooltip2 = L["None found"]
	end
	
	row.tooltip = HIGHLIGHT_FONT_COLOR_CODE .. row.tooltip .. FONT_COLOR_CODE_CLOSE
	row:Show()
	
	for _, gem in pairs( GemTotals ) do
		i = i + 1
		
		row = getglobal( "PlayerStatFrameRight" .. i )
		label = getglobal( row:GetName() .. "Label" )
		stat = getglobal( row:GetName() .. "StatText" )

		label:SetText( L["TYPES"][ gem.color ] )
		stat:SetText( gem.count )
		
		row.tooltip = gem.color .. " " .. HIGHLIGHT_FONT_COLOR_CODE .. L["Gem Stats"] ..FONT_COLOR_CODE_CLOSE
		
		local list = {}
		for name, total in pairs( GemStats[ gem.color ] ) do
			table.insert( list, name .. ": " .. GREEN_FONT_COLOR_CODE .. total .. FONT_COLOR_CODE_CLOSE )
		end

		if( #( list ) > 0 ) then
			row.tooltip2 = table.concat( list, "\n" )
		
		elseif( gem.count > 0 ) then
			row.tooltip2 = L["No stats found"]
		else
			row.tooltip = nil
			row.tooltip2 = nil
		end
		
		row:Show()
	end
	
	PlayerStatFrameRight6:Hide()
end

function GemCount:UpdatePaperdollStats( prefix, index )
	if( prefix == "PLAYERSTAT_GEM_COUNT" ) then
		GemCount:UpdatePaperdollGems()
	end
end

function GemCount:AddGemColor( color, statName, statAmount )
	for id, gem in pairs( GemTotals ) do
		if( gem.color == color ) then
			GemTotals[ id ].count = gem.count + 1
			GemByName[ gem.color ] = GemTotals[ id ].count
			
			if( not GemStats[ gem.color ][ statName ] ) then
				GemStats[ gem.color ][ statName ] = statAmount
			else
				GemStats[ gem.color ][ statName ] = GemStats[ gem.color ][ statName ] + statAmount
			end
			
			break
		end
	end
end

function GemCount:ParseStat( text )
	text = string.trim( text )
	
	if( string.find( text, L["\+([0-9]+) ([^!]+)"] ) ) then
		local _, _, amount, name = string.find( text, L["\+([0-9]+) ([^!]+)"] )
		return string.trim( name ), tonumber( amount )
	
	elseif( string.find( text, L["([^!]+) \+([0-9]+)"] ) ) then
		local _, _, name, amount = string.find( text, L["([^!]+) \+([0-9]+)"] )
		return string.trim( name ), tonumber( amount )
	end
	
	return nil, nil
end


function GemCount:ScanGem( itemLink )
	-- We have to clear lines because if we scan the same link
	-- it'll close the tooltip instead and error
	self.tooltip:ClearLines()
	self.tooltip:SetHyperlink( itemLink )

	if( self.tooltip:NumLines() == 0 ) then
		return
	end
	
	local text = getglobal( self.tooltip:GetName() .. "TextLeft" .. self.tooltip:NumLines() ):GetText()
	
	-- First step, figure out type
	if( string.find( text, L["Only fits in a meta gem slot"] ) ) then
		local reqList = { string.split( "\n", getglobal( self.tooltip:GetName() .. "TextLeft" .. self.tooltip:NumLines() - 1 ):GetText() ) }
		local color, thenColor, countReq

		local inactive = 0
		
		for _, text in pairs( reqList ) do
			text = string.trim( text )
			
			if( string.find( text, L["Requires more (.+) gems than (.+) gems"] ) ) then
				_, _, color, thenColor = string.find( text, L["Requires more (.+) gems than (.+) gems"] )
				table.insert( MetaGem.reqs, { type = "more", moreColor = ColorByLocal[ color ], thenColor = ColorByLocal[ thenColor ] } )

			elseif( string.find( text, L["Requires at least ([0-9]+) (.+) gems"] ) ) then
				_, _, countReq, color = string.find( text, L["Requires at least ([0-9]+) (.+) gems"] )
				table.insert( MetaGem.reqs, { type = "least", count = countReq, color = ColorByLocal[ color ] } )
			end
			
			-- Check for any inactive bonuses
			if( string.find( text, "^|cff808080" ) ) then
				inactive = inactive + 1
			end
		end
		
		if( inactive == 0 ) then
			MetaGem.status = "active"
		else
			MetaGem.status = "inactive"
		end

		return
	end
	
	local stat = getglobal( self.tooltip:GetName() .. "TextLeft" .. self.tooltip:NumLines() - 1 ):GetText()
	
	-- Prismatic gem
	if( string.find( text, L["Matches a (.+), (.+) or (.+) Socket"] ) ) then
		self:AddGemColor( "Prismatic", self:ParseStat( stat ) )
	
	-- Hybrid gem
	elseif( string.find( text, L["Matches a (.+) or (.+) Socket"] ) ) then
		local _, _, color1, color2 = string.find( text, L["Matches a (.+) or (.+) Socket"] )
		local stat1, stat2
		
		color1 = ColorByLocal[ color1 ]
		color2 = ColorByLocal[ color2 ]
		
		if( string.find( stat, L["(.+) and (.+)"] ) ) then
			_, _, stat1, stat2 = string.find( stat, L["(.+) and (.+)"] )
			
		elseif( string.find( stat, L["(.+), (.+)"] ) ) then
			_, _, stat1, stat2 = string.find( stat, L["(.+), (.+)"] )
		end
		
		local name1, amount1 = self:ParseStat( stat1 )
		local name2, amount2 = self:ParseStat( stat2 )
		
		--[[
		It's annoying, but the gem color and stats don't always match up
		hit is yelow, AGI is red.

		Glinting Noble Topaz 
		+4 Hit Rating and +4 Agility
		"Matches a Red or Yellow Socket." 
		]]
		
		if( L["STATS"][ color1 ][ name1 ] ) then
			self:AddGemColor( color1, L["STATS"][ color1 ][ name1 ], amount1 )
			self:AddGemColor( color2, L["STATS"][ color2 ][ name2 ], amount2 )
		else
			self:AddGemColor( color1, L["STATS"][ color1 ][ name2 ], amount2 )
			self:AddGemColor( color2, L["STATS"][ color2 ][ name1 ], amount1 )
		end
		
	-- Regular gem
	elseif( string.find( text, L["Matches a (.+) Socket"] ) ) then
		local _, _, color = string.find( text, L["Matches a (.+) Socket"] )
		local name, amount = self:ParseStat( stat )
		
		self:AddGemColor( ColorByLocal[ color ], L["STATS"][ color ][ name ], amount )
	end
	
end

local function SortGems( a, b )
	if( not b ) then
		return false
	end
	
	if( a.count == b.count ) then
		return ( a.color > b.color )
	end
	
	return ( a.count > b.count )
end

function GemCount:ScanItems()
	MetaGem.status = "none"
	MetaGem.reqs = {}
	
	for id, gem in pairs( GemTotals ) do
		GemTotals[ id ].count = 0
		GemByName[ gem.color ] = 0
		GemStats[ gem.color ] = {}
	end

	local i, slotid, itemLink, socketGems, gemLink
	local jewel1, jewel2, jewel3, jewel4

	for _, slot in pairs( slots ) do
		slotid = GetInventorySlotInfo( slot )
		itemLink = GetInventoryItemLink( "player", slotid )
		
		if( itemLink ) then
			for i=1, 3 do
				_, gemLink = GetItemGem( itemLink, i )
				if( gemLink ) then
					self:ScanGem( gemLink )
				end
			end
		end
	end

	table.sort( GemTotals, SortGems )
end

local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", function(self, event, addon)
	if( event == "ADDON_LOADED" and addon == "GemCount" ) then
		GemCount.Enable(GemCount)
	elseif( event == "PLAYER_DAMAGE_DONE_MODS" or event == "UNIT_STATS" ) then
		GemCount.ScanItems(GemCount)
		GemCount.UpdatePaperdollGems(GemCount)
	end
end)
frame:RegisterEvent("ADDON_LOADED")