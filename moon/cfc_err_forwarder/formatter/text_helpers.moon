getSourceURL = include "get_source_url.lua"

bold = (text) -> "**#{text}**"
code = (text, language="") -> "```#{language}\n#{text}```"

timestamp = (ts) -> "<t:#{ts}:R>"

bad = (text) -> code "- #{text}", "diff"

to64 = util.SteamIDTo64
steamIDLink = (id) -> "[#{id}](https://steamid.io/lookup/#{to64 id})"

truncate = (text="<empty>", max=1024) ->
    return text if #text < max
    "#{string.Left text, max - 10}..."

getSourceText = (data) ->
    :sourceFile, :sourceLine = data

    sourceURL = getSourceURL sourceFile, sourceLine
    sourceLink = sourceURL and "[Line with Context](#{sourceURL})" or ""

    sourceText = code "#{sourceFile}:#{sourceLine}"

    "#{sourceLink}\n#{sourceText}"

:bad, :bold, :code, :steamIDLink, :truncate, :timestamp, :getSourceText
