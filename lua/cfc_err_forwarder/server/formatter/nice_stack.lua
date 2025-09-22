local table_concat = table.concat
local table_insert = table.insert
local string_format = string.format

local spacingTable = {} do
    for i = 0, 20 do
        spacingTable[i] = string.rep( " ", i )
    end
end

local function formatStackInfo( stack )
    local lines = {}
    local indent = -1

    for i = 1, #stack do
        indent = indent + 1
        local item = stack[i]

        local lineNumber = item.currentline
        local src = item.short_src or item.source or "<unknown source>"

        local name = item.name or ""

        name = #name == 0 and "<unknown>" or name

        local spacing = spacingTable[indent]
        table_insert( lines, string_format( "%s%s. %s - %s:%s", spacing, i, name, src, lineNumber ) )
    end

    return table_concat( lines, "\n" )
end

function ErrorForwarder.NiceStack( data )
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
