local MAX_LOCALS = 8

--- @param data ErrorForwarder_QueuedError
--- @return string[]
return function( data )
    local locals
    local stack = data.luaError.stack

    for _, level in ipairs( stack ) do
        if locals then break end
        if level then
            locals = level.locals
        end
    end

    if not locals then return end
    if table.Count( locals ) == 0 then return end

    local out = {}
    local longest = 0
    for name, value in pairs( locals ) do
        longest = #name > longest and #name or longest
        table.insert( out, { name = name, value = value } )
    end

    local function convert( line )
        local name, value = line.name, line.value
        local spacing = string.rep( " ", longest - #name )
        return string.format( "%s %s= %s", name, spacing, value )
    end

    local maxLocals = math.min( MAX_LOCALS, #out )
    for i = 1, maxLocals do
        out[i] = convert( out[i] )
    end
end
