--- @param data ErrorForwarder_QueuedError
--- @return string
return function( data )
    local indent = 2
    local lines = { data.luaError.fullError or "<unknown error>" }

    local stack = data.luaError.stack

    for i = 1, #stack do
        indent = indent + 1
        local item = stack[i]

        local lineNumber = item.currentLine
        local src = item.short_src or item.source or "<unknown source>"

        local name = item.name or ""
        name = #name == 0 and "<unknown>" or name

        local spacing = string.rep( " ", indent )
        table.insert( lines, string.format( "%s%s.  %s - %s:%s", spacing, i, name, src, lineNumber ) )
    end

    return table.concat( lines, "\n" )
end
