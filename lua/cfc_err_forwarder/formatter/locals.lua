local MAX_LOCALS = 8

--- @param data ErrorForwarder_QueuedError
--- @return string?
return function( data )
    local stack = data
    local locals

    for _, level in ipairs( stack ) do
        if not locals and level then
            locals = level
        end
    end

    if not locals then return nil end
    if #locals == 0 then return nil end

    local out = {}
    local longest = 0
    for name, value in pairs( locals ) do
        if #name > longest then longest = #name end
        table.insert( out, { name = name, value = value } )
    end

    local function convert( line )
        local name = line.name
        local value = line.value
        local spacing = string.rep( " ", longest - #name )
        return name .. spacing .. "= " .. value
    end

    local maxLocals = math.min( MAX_LOCALS, #out )
    local limitedOut = {}
    for i = 1, maxLocals do
        table.insert( limitedOut, convert( out[i] ) )
    end

    return table.concat( limitedOut, "\n" )
end
