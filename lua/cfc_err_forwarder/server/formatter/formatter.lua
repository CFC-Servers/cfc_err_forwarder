-- Colors from: https://github.com/Facepunch/garrysmod/blob/dfdafba0f04e75be122961291a56d9c1714a3d8a/garrysmod/lua/menu/problems/problem_lua.lua#L3-L5
local clientError = 0xFFDE66
local serverError = 0x89DEFF

local niceStack = include( "nice_stack.lua" )
local values = include( "values_short.lua" )

--- @type ErrorForwarder_TextHelpers
local TextHelpers = include( "text_helpers.lua" )
local bold = TextHelpers.bold
local code = TextHelpers.code
local codeLine = TextHelpers.codeLine
local truncate = TextHelpers.truncate
local getMessageFromError = TextHelpers.getMessageFromError

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
                name = "Stack",
                value = code( truncate( niceStack( data ) ) )
            },
        }

        if data.fullContext then
            local localsData = values( data.fullContext.locals, "locals" )
            if localsData then
                table.insert( fields, {
                    name = "Locals",
                    value = code( truncate( localsData ), "ini" )
                } )
            end
        end

        if client then
            table.insert( fields, {
                name = "Player",
                value = bold( data.plyName .. " [" .. data.plySteamID .. "](" .. TextHelpers.steamIDLink( data.plySteamID ) .. ")" )
            } )
        end

        table.insert( fields, {
            name = "Count",
            value = bold( data.count ),
            inline = true
        } )

        if data.branch then
            table.insert( fields, {
                name = "Branch",
                value = bold( TextHelpers.gmodBranch( data.branch ) ),
                inline = true
            } )
        end

        if data.systemOS then
            table.insert( fields, {
                name = "OS",
                value = bold( data.systemOS ),
                inline = true
            } )
        end

        if data.country then
            table.insert( fields, {
                name = "Country / Ping",
                value = bold( data.country ) .. " :flag_" .. data.country:lower() .. ":" .. " / " .. codeLine( data.ping .. "ms" ),
                inline = true
            } )
        end

        if data.gmodVersion then
            table.insert( fields, {
                name = "GMod Version",
                value = bold( data.gmodVersion ),
                inline = true
            } )
        end

        table.insert( fields, {
            name = "Map",
            value = codeLine( game.GetMap() ),
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
                color = client and clientError or serverError,
                title = realm .. " Error",
                author = { name = GetHostName() },
                description = TextHelpers.bad( getMessageFromError( data.luaError.errorString ) ),
                fields = nonil( fields )
            }
        }
    }
end
