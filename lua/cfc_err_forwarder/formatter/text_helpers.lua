local to64 = util.SteamIDTo64
local getSourceURL = include( "get_source_url.lua" )

--- @class ErrorForwarder_TextHelpers
local TextHelpers = {}

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

--- Formats a timestamp to be a Discord relative time
--- @param ts number
--- @return string
function TextHelpers.timestamp( ts )
    return "<t:" .. ts .. ":R>"
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
    return string.format( "https://steamid.gay/user/%s", to64( steamID ) )
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

    local sourceURL = getSourceURL( sourceFile, sourceLine )
    local sourceLink = sourceURL and string.format( "[Line with Context](%s)", sourceURL ) or ""

    local sourceText = TextHelpers.code( sourceFile .. ":" .. sourceLine, "" )

    return sourceLink .. "\n" .. sourceText
end

--- Formats the given branch into a human friendly name
--- @param branch string
--- @return string
function TextHelpers.gmodBranch( branch )
    return branch == "unknown" and "main" or branch
end

return TextHelpers
