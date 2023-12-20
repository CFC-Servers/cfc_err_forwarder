local table_concat = table.concat
local table_insert = table.insert
local string_format = string.format

local GetSource = include( "get_source_url.lua" )
local PrettyFunction = include( "pretty_function.lua" ).FromFile

local function formatStackInfo( stack )
    local lines = {}

    for i = 1, #stack do
        local item = stack[i]

        local lineNumber = item.currentline
        local src = item.short_src or item.source or "<unknown source>"

        local name = item.name or ""
        name = #name == 0 and "<unknown>" or name

        local sourceInfo = src .. ":" .. lineNumber
        local prettyName = PrettyFunction( src, lineNumber )

        print( "Pretty name for ", sourceInfo, "is", prettyName )
        if prettyName == "<unknown>" then prettyName = nil end

        local link = GetSource( src, lineNumber )

        if link then
            table_insert( lines, string_format( "%s. [**%s**](%s)", i, prettyName or name, link ) )
        else
            -- __newindex → `[C]:-1`
            sourceInfo = string_format( "`%s`", sourceInfo )
            table_insert( lines, string_format( "%s. **%s** → %s", i, name, sourceInfo ) )
        end
    end

    return table_concat( lines, "\n" )
end

return function( data )
    local err = data.luaError
    local stack = err.stack

    if table.IsEmpty( stack ) then
        -- If we don't have any stack info, we just make it up
        stack = {
            {
                currentline = err.sourceLine,
                name = "<unknown>",
                short_src = err.sourceFile
            }
        }
    end

    return formatStackInfo( stack )
end
