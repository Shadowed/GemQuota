if( GetLocale() ~= "frFR" ) then
	return
end

GemQuotaLocals = setmetatable({
}, {__index = GemQuotaLocals })
