if( GetLocale() ~= "deDE" ) then
	return
end

GemQuotaLocals = setmetatable({
}, {__index = GemQuotaLocals })
