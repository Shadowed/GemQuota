GemQuotaLocals = {
	["Healing"] = "Healing",
	["Total stats"] = "Total stats",
	["No stats found"] = "No stats found",
	["Gem Info"] = "Gem Info",
	
	["Failed to match %s no stats found. Please report the gem name to the comments at WoWInterface.com so this can be fixed."] = "Failed to match %s no stats found. Please report the gem name to the comments at WoWInterface.com so this can be fixed.",
	
	["Dodge Rating"] = "Dodge Rating",
	["Spell Crit"] = "Spell Crit",
	["Melee Crit"] = "Melee Crit",
	["Spell Hit"] = "Spell Hit",
	["Melee Hit"] = "Melee Hit",
	["Defense Rating"] = "Defense Rating",
	["Spell Haste"] = "Spell Haste",
	["Parry Rating"] = "Parry Rating",
	["Resilience Rating"] = "Resilience Rating",
	
	["MATCHES"] = {
		-- You'll need to localize both keys in this table
		-- as it's formated as "[<gem text>] = <modifier>"
		-- The gem text should be in lower case (as it's case-insensitive)
		-- It doesn't have to be the full text, but enough for a unique match
		["Red"] = {
			["([0-9]+) strength"] = "Strength",
			["([0-9]+) attack"] = "Attack Power",
			["([0-9]+) agility"] = "Agility",
			["([0-9]+) healing"] = "Healing",
			["([0-9]+) spell damage"] = "Spell Damage",
			["spell damage %+([0-9]+)"] = "Spell Damage",
			["([0-9]+) parry rating"] = "Parry Rating",
			["([0-9]+) dodge rating"] = "Dodge Rating",
		},
		["Blue"] = {
			["([0-9]+) stamina"] = "Stamina",
			["stamina ([0-9]+)"] = "Stamina",
			["([0-9]+) mana"] = "Mana per 5",
			["([0-9]+) spirit"] = "Spirit",
			["([0-9]+) spell penet"] = "Spell Penetration",
		},
		["Yellow"] = {
			["([0-9]+) spell crit"] = "Spell Crit",
			["([0-9]+) intellect"] = "Intellect",
			["([0-9]+) defense rating"] = "Defense Rating",
			["([0-9]+) spell hit"] = "Spell Hit",
			["([0-9]+) resilience"] = "Resilience Rating",
			["([0-9]+) hit rating"] = "Melee Hit",
			["([0-9]+) crit"] = "Melee Crit",
			["([0-9]+) spell haste"] = "Spell Haste",
		},
		["Prismatic"] = {
			["([0-9]+) resist"] = "All Resist",
		},
	},
			
	-- Meta gem
	["inactive"] = "Inactive",
	["active"] = "Active",
	["none"] = "None",
	["None"] = "None",
	["Meta"] = "Meta",
	
	["Equipped Meta Gem"] = "Equipped Meta Gem",
	["Currently active"] = "Currently active",
	["Requirements"] = "Requirements",
	
	["At least %d %s, have %d."] = "At least %d %s, have %d.",
	["More %s than %s, have %d %s and %d %s."] = "More %s than %s, have %d %s and %d %s.",
	["Exactly %d %s, have %d."] = "Exactly %d %s, have %d.",
	["Exactly %d %s, only have %d."] = "Exactly %d %s, only have %d.",
	
	["At least %d %s, only have %d."] = "At least %d %s, only have %d.",
	["More %s than %s, only have %d %s and %d %s."] = "More %s than %s, only have %d %s and %d %s.",
	
	["Requires more (.+) gems than (.+) gems"] = "Requires more (.+) gems than (.+) gems",
	["Requires at least ([0-9]+) (.+) gems"] = "Requires at least ([0-9]+) (.+) gems",
	["Requires exactly ([0-9]+) (.+) gems"] = "Requires exactly ([0-9]+) (.+) gems",
	
	-- Gem types
	["COLORS"] = {"Red", "Blue", "Yellow"},
	
	-- Both fields need to be localized
	["Purple"] = {"Red", "Blue"},
	["Green"] = {"Blue", "Yellow"},
	["Orange"] = {"Red", "Yellow"},
	["Prismatic"] = {"Red", "Blue", "Yellow"},
}	