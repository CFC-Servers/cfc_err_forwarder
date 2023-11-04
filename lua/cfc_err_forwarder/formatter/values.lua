local fmt = string.format
local string_rep = string.rep

--- Formats a value in its short form
--- @param details RawValueDetails
local function formatShortValue( details )
    local shortData = details.short or {}
    local shortVal = tostring( shortData.val or details._val )

    if shortVal then
        shortVal = string.sub( shortVal, 1, 30 )
    else
        shortVal = ""
    end

    -- An empty name means we display the value as-is
    local name = shortData.name or details.name
    if name ~= "" then
        name = name .. " "
        shortVal = fmt( "[%s]", shortVal )
    end

    return name .. shortVal
end

local formatValueData

local function formatDataTable( data, level, lines )
    level = level or 2
    lines = lines or "{\n"

    local spacing = string_rep( " ", level )

    local keys = table.GetKeys( data )
    local keyCount = #keys

    for i = 1, keyCount do
        local key = keys[i]
        local value = data[key]

        lines = lines .. spacing
        lines = lines .. key .. " = " .. value.name .. " ["
        if value.data then
            lines = lines .. formatDataTable( value.data, level + 2 )
        else
            lines = lines .. tostring( value )
        end

        lines = lines .. "\n"
    end

    lines = lines .. string_rep( " ", level - 2 ) .. "}]"

    return lines
end

--- Formats s value in its long form
--- @param details RawValueDetails
--- @return string, string
formatValueData = function( details, level )
    local value

    local data = details.data
    if data then
        if next( data ) then
            value = formatDataTable( data )
        else
            value = ""
        end
    else
        local shortData = details.short or {}
        value = tostring( shortData.val or details._val or details )
    end

    return details.name, value
end


--- @class ProcessedStack
--- @field upvales any?
--- @field locals any?
--- @field stackLevel number
--- @field funcName string
--- @field fileAndLine string

--- Formats the given stack (already run through the context tool)
--- @param stack ProcessedStack
--- @param short boolean Whether or not to output a shortened version of the context
--- @param valueType string Either "upvalues" or "locals"
return function( stack, valueType, limit, short )
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

    local out = ""

    local names = table.GetKeys( values )
    local maxValues = math.min( limit, #names )

    for i = 1, maxValues do
        local varName = names[i]
        local details = values[varName]

        local typeName
        local val

        if short then
            val = formatShortValue( details )
            out = out .. fmt( "%s = %s\n", varName, val )
        else
            typeName, val = formatValueData( details )
            out = out .. fmt( "%s = %s [%s]\n", varName, typeName, val )
        end
    end

    return out
end
