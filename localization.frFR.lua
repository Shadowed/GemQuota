if( GetLocale() ~= "frFR" ) then
	return;
end

GemCountLocals = setmetatable( {

}, { __index = GemCountLocals } );

