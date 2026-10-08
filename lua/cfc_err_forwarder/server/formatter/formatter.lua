-- Colors from: https://github.com/Facepunch/garrysmod/blob/dfdafba0f04e75be122961291a56d9c1714a3d8a/garrysmod/lua/menu/problems/problem_lua.lua#L3-L5
local clientError = 0xFFDE66
local serverError = 0x89DEFF

local niceStack = ErrorForwarder.NiceStack
local escape = ErrorForwarder.TextHelpers.escape
local bold = ErrorForwarder.TextHelpers.bold
local code = ErrorForwarder.TextHelpers.code
local codeLine = ErrorForwarder.TextHelpers.codeLine
local truncate = ErrorForwarder.TextHelpers.truncate
local getSourceText = ErrorForwarder.TextHelpers.getSourceText
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

-- Error display format matching the game's console error output
local function gmodErrorText( data )
    local err = data.luaError
    local errorString = err.errorString or err.fullError or ""

    if errorString == "" then return niceStack( data ) end

    local addonTitle = err.addonTitle
    local prefix = addonTitle and addonTitle ~= "" and ( "[" .. addonTitle .. "] " ) or ""

    errorString = string.Replace( errorString, "\t", ( " " ):rep( 12 ) )

    return prefix .. errorString .. "\n" .. niceStack( data )
end

--- @param data ErrorForwarder_QueuedError
function ErrorForwarder.Formatter( data )
    local client = data.isClientside
    local realm = client and "Client" or "Server"

    local fields
    do
        fields = {}

        if client then
            table.insert( fields, {
                name = "Player",
                value = bold( escape( data.plyName ) .. " [" .. data.plySteamID .. "](" .. ErrorForwarder.TextHelpers.steamIDLink( data.plySteamID ) .. ")" )
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
                value = bold( escape( ErrorForwarder.TextHelpers.gmodBranch( data.branch ) ) ),
                inline = true
            } )
        end

        if data.systemOS then
            table.insert( fields, {
                name = "OS",
                value = bold( escape( data.systemOS ) ),
                inline = true
            } )
        end

        if data.country then
            local escapedCountry = escape( data.country )

            table.insert( fields, {
                name = "Country / Ping",
                value = bold( escapedCountry ) .. " :flag_" .. escapedCountry:lower() .. ":" .. " / " .. codeLine( data.ping .. "ms" ),
                inline = true
            } )
        end

        if data.gmodVersion then
            table.insert( fields, {
                name = "GMod Version",
                value = bold( escape( data.gmodVersion ) ),
                inline = true
            } )
        end

        table.insert( fields, {
            name = "Map",
            value = codeLine( escape( game.GetMap(), true ) ),
            inline = true
        } )

        if client and data.timeConnected then
            table.insert( fields, {
                name = "Time Connected",
                value = codeLine( ErrorForwarder.TextHelpers.nicetime( data.timeConnected ) ),
                inline = true
            } )
        end

        table.insert( fields, {
            name = "Server Uptime",
            value = "Real time " .. codeLine( ErrorForwarder.TextHelpers.nicetime( os.time() - ErrorForwarder.StartTime ) ) .. "\n Curtime " .. codeLine( ErrorForwarder.TextHelpers.nicetime( CurTime() ) ),
            inline = true
        } )

        table.insert( fields, {
            name = "Most recent occurrence",
            value = ErrorForwarder.TextHelpers.timestamp( data.lastOccurredAt ),
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
                description = code( truncate( escape( gmodErrorText( data ), true ), 3700 ) ),
                fields = nonil( fields )
            }
        }
    }
end
