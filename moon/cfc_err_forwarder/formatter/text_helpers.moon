getSourceURL = include "get_source_url.lua"

bold = (text) -> "**#{text}**"
code = (text, language="") -> "```#{language}\n#{text}```"

timestamp = (ts) -> "<t:#{ts}:R>"

bad = (text) ->
    text = "- #{text}"
    code text, "diff"

steamIDLink = (steamID) ->
    steamID64 = util.SteamIDTo64 steamID
    "[#{steamID}](https://steamid.io/lookup/#{steamID64})"

truncate = (text, max=1024) ->
    return text if #text < max
    return "#{string.Left text, max - 10}..."

getSourceText = (data) ->
    :sourceFile, :sourceLine = data

    sourceURL = getSourceURL sourceFile, sourceLine
    sourceLink = sourceURL and "[Line with Context](#{sourceURL})" or ""

    sourceText = code "#{sourceFile}:#{sourceLine}"

    "#{sourceLink}\n#{sourceText}"

:bad, :bold, :code, :steamIDLink, :truncate, :timestamp, :getSourceText
