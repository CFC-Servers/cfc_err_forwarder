local to64 = util.SteamIDTo64
local string_find = string.find
local string_sub = string.sub
local string_len = string.len

--- @class ErrorForwarder_TextHelpers
local TextHelpers = {}
ErrorForwarder.TextHelpers = TextHelpers

--- Formats a text to be bold
--- @param text string
--- @return string
function TextHelpers.bold( text )
    return "**" .. text .. "**"
end

--- Formats a text to be a code block
--- @param text string
--- @param language string
--- @return string
function TextHelpers.code( text, language )
    return "```" .. ( language or "" ) .. "\n" .. text .. "\n```"
end

--- Formats a text to be a code line
--- @param text string
--- @return string
function TextHelpers.codeLine( text )
    return "`" .. text .. "`"
end

--- Formats a timestamp to be a Discord relative time
--- @param ts number
--- @return string
function TextHelpers.timestamp( ts )
    return "<t:" .. ts .. ":R>"
end

--- Formats a duration in seconds to a human readable uptime
--- @param seconds number
--- @return string
function TextHelpers.nicetime( seconds )
    local hours = math.floor( seconds / 3600 )
    local minutes = math.floor( ( seconds % 3600 ) / 60 )
    seconds = seconds % 60

    if hours > 0 then
        return string.format( "%dh %dm", hours, minutes )
    elseif minutes > 0 then
        return string.format( "%dm", minutes )
    else
        return string.format( "%ds", seconds )
    end
end

--- Formats a text to be red
--- @param text string
--- @return string
function TextHelpers.bad( text )
    return TextHelpers.code( "- " .. text, "diff" )
end

--- Gets a formatted link to the given SteamID
--- @param steamID string
--- @return string
function TextHelpers.steamIDLink( steamID )
    return string.format( "https://steamid.gg/user/%s", to64( steamID ) )
end

--- Truncates a given field to the given max length
--- (Also closes quotes)
--- @param text string
--- @param max number
--- @return string
function TextHelpers.truncate( text, max )
    max = max or 1024
    text = text or "<empty>"
    if #text <= max then return text end

    if text[1] == [["]] then
        return text:sub( 1, max - 4 ) .. [["...]]
    else
        return text:sub( 1, max - 3 ) .. "..."
    end
end

--- Gets a formatted link to view the source code
--- @param data ErrorForwarder_QueuedError
--- @return string
function TextHelpers.getSourceText( data )
    local sourceFile = data.luaError.sourceFile
    local sourceLine = data.luaError.sourceLine

    if sourceFile == "[C]" then
        for _, stackLine in ipairs( data.luaError.stack ) do
            if stackLine.source ~= "[C]" then
                sourceFile = stackLine.source
                sourceLine = stackLine.currentline
                break
            end
        end
    end

    if not sourceFile or not sourceLine then return "" end

    local sourceURL = ErrorForwarder.GetSourceURL( sourceFile, sourceLine )
    local sourceLink = sourceURL and string.format( "[Line with Context](%s)", sourceURL ) or ""

    local sourceText = TextHelpers.code( sourceFile .. ":" .. sourceLine, "" )

    return sourceLink .. "\n" .. sourceText
end

--- Takes a full <error>:<line>: <message> and returns the message
--- @param errorString string
function TextHelpers.getMessageFromError( errorString )
    local firstColon = string_find( errorString, ":", 1, true )
    if not firstColon then return errorString end

    local secondColon = string_find( errorString, ":", firstColon + 1, true )
    if not secondColon then return errorString end

    -- +2 to skip the ": "
    local message = string_sub( errorString, secondColon + 2 )
    if string_len( message ) == 0 then return errorString end

    return message
end

--- Formats the given branch into a human friendly name
--- @param branch string
--- @return string
function TextHelpers.gmodBranch( branch )
    return branch == "unknown" and "main" or branch
end
