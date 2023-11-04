local fmt = string.format
local math_min = math.min
local string_rep = string.rep
local table_insert = table.insert
local table_concat = table.concat

local MAX_LOCALS = 8

--- Formats s value in its long form
local function formatValueData( details, val )
    local value

    local data = details.data
    if data then
        value = util.TableToJSON( data, true )
    else
        value = tostring( val )
    end

    return details.type .. " [\n" .. value .. "\n]\n"
end

--- Formats a value in its short form
--- @param details RawValueDetails
local function formatShortValue( details )
    local shortData = details.short or {}

    local name = shortData.name or details.type
    local shortVal = shortData.val

    if shortVal then
        shortVal = string.sub( shortVal, 1, 20 )
    else
        shortVal = ""
    end

    return fmt( "%s [%s]", name, shortVal )
end

--- Takes a value, returns a full or shortened pretty version
--- @param val any
--- @param short boolean Whether or not to return the short version
--- @return string
local function prettyRawValue( details, short )
    if short then
        return formatShortValue( details )
    else
        return formatValueData( details, val )
    end
end


--- @return string?
return function( stack, limit, short )
    local locals

    -- Find the toppest recent stack with locals
    -- TODO: This seems dumb - surely there's a better way to find the relevant locals?
    for _, level in ipairs( stack ) do
        local levelLocals = level.locals or {}

        if table.Count( levelLocals ) > 0 then
            locals = levelLocals
            break
        end
    end

    if not locals then return nil end
    if table.Count( locals ) == 0 then return nil end

    local out = {}
    local longest = 0
    for name, value in pairs( locals ) do
        if #name > longest then longest = #name end
        table_insert( out, { name = name, value = value } )
    end

    local function convert( line )
        local name = line.name
        local value = line.value
        value = prettyRawValue( value, short )

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
