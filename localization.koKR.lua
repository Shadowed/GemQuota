if( GetLocale() ~= "koKR" ) then
	return;
end

GemCountLocals = setmetatable( {
	["none"] = "??",
}, { __index = GemCountLocals } );