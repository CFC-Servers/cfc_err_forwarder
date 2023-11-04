local red = 14483456
local locals = include( "locals.lua" )
local niceStack = include( "nice_stack.lua" )

local TextHelpers = include( "text_helpers.lua" )
local bold = TextHelpers.bold
local code = TextHelpers.code
local truncate = TextHelpers.truncate

local function nonil( t )
    local ret = {}
    for _, v in ipairs( t ) do
        if v ~= nil then
            table.insert( ret, v )
        end
    end

    return ret
end

--- @param data ErrorForwarder_QueuedError
return function( data )
    local client = data.isClientside
    local realm = client and "Client" or "Server"

    local fields
    do
        fields = {
            {
                name = "Source File",
                value = TextHelpers.getSourceText( data )
            },
            {
                name = "Full Error",
                value = code( truncate( client and data.luaError.fullError or niceStack( data ) ) )
            },
        }

        local localsData = locals( data.fullContext.locals, 8, true )
        if localsData then
            table.insert( fields, {
                name = "Locals",
                value = code( truncate( localsData ), "m" )
            } )
        end

        if data.isClientside then
            table.insert( fields, {
                name = "Player",
                value = bold( data.plyName .. " ( " .. TextHelpers.steamIDLink( data.plySteamID ) .. " )" )
            } )
        end

        if data.branch then
            table.insert( fields, {
                name = "Branch",
                value = bold( TextHelpers.gmodBranch( data.branch ) ),
                inline = true
            } )
        end

        table.insert( fields, {
            name = "Count",
            value = bold( data.count ),
            inline = true
        } )

        table.insert( fields, {
            name = "Most recent occurrence",
            value = TextHelpers.timestamp( data.luaError.occurredAt ),
            inline = true
        } )
    end

    return {
        content = "",
        embeds = {
            {
                color = red,
                title = realm .. " Error",
                author = { name = GetHostName() },
                description = TextHelpers.bad( data.luaError.errorString ),
                fields = nonil( fields )
            }
        }
    }
end
