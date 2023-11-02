local math_min = math.min
local string_rep = string.rep
local table_insert = table.insert
local table_concat = table.concat

local MAX_LOCALS = 8

--- @param data ErrorForwarder_QueuedError
--- @return string?
return function( data, limit )
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
        table_insert( out, { name = name, value = value } )
    end

    local function convert( line )
        local name = line.name
        local value = line.value
        local spacing = string_rep( " ", longest - #name )
        return name .. spacing .. "= " .. value
    end

    local maxLocals = math_min( limit or MAX_LOCALS, #out )
    local limitedOut = {}
    for i = 1, maxLocals do
        table_insert( limitedOut, convert( out[i] ) )
    end

    return table_concat( limitedOut, "\n" )
end
