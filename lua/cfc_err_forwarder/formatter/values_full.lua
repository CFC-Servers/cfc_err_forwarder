MAX_VALUES_LIMIT = 50

local canRaw = {
    String = true,
    Number = true,
    Boolean = true,
}

local function dedentTopLevelKeys( str )
    local lines = {}

    -- Split the input into lines
    for line in str:gmatch( "[^\r\n]+" ) do
        -- Remove the leading spaces or tabs from each line
        local dedentedLine = line:gsub( "^\t", "" )
        table.insert( lines, dedentedLine )
    end

    -- Concatenate the lines back together
    return table.concat( lines, "\n" )
end

local formatFull
formatFull = function ( struct )
    if isstring( struct ) then return struct end

    local name = struct.name or ""
    local val = struct.val

    if canRaw[name] then
        return val
    end

    local data = struct.data
    if name == "Table" then
        local newData = {}
        for n, v in pairs( data ) do
            newData[n] = formatFull( v )
        end

        return newData
    end

    return {
        Type = name,
        Data = data
    }
end

--- Formats the given stack (already run through the context tool)
--- @param stack ProcessedStack
--- @param valueType string Either "upvalues" or "locals"
return function( stack, valueType )
    local values

    -- Find the toppest recent stack with locals/upvalues
    -- TODO: This seems dumb - surely there's a better way?
    for _, level in ipairs( stack ) do
        local levelValues = level[valueType] or {}

        if table.Count( levelValues ) > 0 then
            values = levelValues
            break
        end
    end

    if not values then return nil end
    if table.Count( values ) == 0 then return nil end

    local out = {}
    local names = table.GetKeys( values )
    local maxValues = math.min( MAX_VALUES_LIMIT, #names )

    for i = 1, maxValues do
        local varName = names[i]
        local details = values[varName]

        out[varName] = formatFull( details )
    end

    local output = util.TableToJSON( out, true )
    output = dedentTopLevelKeys( output )
    output = string.Replace( output, "\t", "    " )

    return output
end
