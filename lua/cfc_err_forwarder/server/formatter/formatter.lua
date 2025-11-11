-- Colors from: https://github.com/Facepunch/garrysmod/blob/dfdafba0f04e75be122961291a56d9c1714a3d8a/garrysmod/lua/menu/problems/problem_lua.lua#L3-L5
local clientError = 0xFFDE66
local serverError = 0x89DEFF

local niceStack = ErrorForwarder.NiceStack
local bold = ErrorForwarder.TextHelpers.bold
local code = ErrorForwarder.TextHelpers.code
local codeLine = ErrorForwarder.TextHelpers.codeLine
local truncate = ErrorForwarder.TextHelpers.truncate
local getMessageFromError = ErrorForwarder.TextHelpers.getMessageFromError
ErrorForwarder.StartTime = ErrorForwarder.StartTime or os.time()

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
function ErrorForwarder.Formatter( data )
    local client = data.isClientside
    local realm = client and "Client" or "Server"

    local fields
    do
        fields = {
            {
                name = "Source File",
                value = ErrorForwarder.TextHelpers.getSourceText( data )
            },
            {
                name = "Stack",
                value = code( truncate( niceStack( data ) ) )
            },
        }

        if client then
            table.insert( fields, {
                name = "Player",
                value = bold( data.plyName .. " [" .. data.plySteamID .. "](" .. ErrorForwarder.TextHelpers.steamIDLink( data.plySteamID ) .. ")" )
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
                value = bold( ErrorForwarder.TextHelpers.gmodBranch( data.branch ) ),
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
            name = "Server Uptime",
            value = "Real time " .. codeLine( ErrorForwarder.TextHelpers.nicetime( os.time() - ErrorForwarder.StartTime ) ) .. "\n Curtime " .. codeLine( ErrorForwarder.TextHelpers.nicetime( CurTime() ) ),
            inline = true
        } )

        table.insert( fields, {
            name = "Most recent occurrence",
            value = ErrorForwarder.TextHelpers.timestamp( data.luaError.occurredAt ),
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
                description = ErrorForwarder.TextHelpers.bad( getMessageFromError( data.luaError.errorString ) ),
                fields = nonil( fields )
            }
        }
    }
end
