if( GetLocale() ~= "deDE" ) then
	return;
end

GemCountLocals = setmetatable( {
}, { __index = GemCountLocals } );
