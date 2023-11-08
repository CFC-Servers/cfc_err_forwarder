--- How many table values to show in short output
local MAX_TABLE_VALUES = 4

--- How many locals to show in short output
local MAX_LOCALS_LIMIT = 25

--- @class ProcessedStack
--- @field upvales any?
--- @field locals any?
--- @field stackLevel number
--- @field funcName string
--- @field fileAndLine string

local function formatShort( struct, inTable )
    if isstring( struct ) then return struct end

    local short = struct.short or {}
    local name = short.name or struct.name or ""
    local val = short.val or struct.val

    if (not inTable) and short.newline then
        local length = #name + #val + 5
        if length > 50 then
            return name .. "\n   └ " .. val
        end
    end

    if name ~= "" then
        return name .. " [" .. val .. "]"
    end

    return tostring( val ) or "<unknown>"
end

local function formatTableData( data )
    local keys = table.GetKeys( data )
    local keyCount = #keys
    local iterCount = math.min( keyCount, MAX_TABLE_VALUES )

    local alert = ""

    if iterCount < keyCount then
        local hiddenCount = keyCout - iterCount
        alert = " (" .. hiddenCount .. " hidden)"
    end

    local out = {
        "Table [" .. keyCount .. "]" .. alert
    }

    for i = 1, iterCount do
        local name = keys[i]
        local details = data[name]

        local line = "  "
        local prefix = i < iterCount and "╞" or "└"
        table.insert( out, line .. prefix .. " " .. name .. " = " .. formatShort( details, true ) )
    end

    return table.concat( out, "\n" )
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
    local maxValues = math.min( MAX_LOCALS_LIMIT, #names )

    for i = 1, maxValues do
        local varName = names[i]
        local details = values[varName]

        local line = "● " .. varName .. " = "

        if details.name == "Table" then
            table.insert( out, line .. formatTableData( details.data ) )
        else
            table.insert( out, line .. formatShort( details, false ) )
        end
    end

    return table.concat( out, "\n\n" )
end
