local table_concat = table.concat
local table_insert = table.insert
local string_format = string.format

local GetSource = include( "get_source_url.lua" )

return function( data )
    local lines = {}

    local stack = data.luaError.stack

    for i = 1, #stack do
        local item = stack[i]

        local lineNumber = item.currentline
        local src = item.short_src or item.source or "<unknown source>"

        local name = item.name or ""
        name = #name == 0 and "<unknown>" or name

        local sourceInfo = src .. ":" .. lineNumber

        local link = GetSource( src, lineNumber )
        if link then
            sourceInfo = string_format( "[`%s`](%s)", sourceInfo, link )
        else
            sourceInfo = string_format( "`%s`", sourceInfo )
        end

        table_insert( lines, string_format( "%s. **%s** → %s", i, name, sourceInfo ) )
    end

    return table_concat( lines, "\n" )
end
