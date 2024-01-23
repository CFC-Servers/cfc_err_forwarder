local getSourceURL = include("get_source_url.lua")
local bold
bold = function(text)
  return "**" .. tostring(text) .. "**"
end
local code
code = function(text, language)
  if language == nil then
    language = ""
  end
  return "```" .. tostring(language) .. "\n" .. tostring(text) .. "```"
end
local timestamp
timestamp = function(ts)
  return "<t:" .. tostring(ts) .. ":R>"
end
local bad
bad = function(text)
  return code("- " .. tostring(text), "diff")
end
local to64 = util.SteamIDTo64
local steamIDLink
steamIDLink = function(id)
  return "[" .. tostring(id) .. "](https://steamid.gay/lookup/" .. tostring(to64(id)) .. ")"
end
local truncate
truncate = function(text, max)
  if text == nil then
    text = "<empty>"
  end
  if max == nil then
    max = 1024
  end
  if #text < max then
    return text
  end
  return tostring(string.Left(text, max - 10)) .. "..."
end
local getSourceText
getSourceText = function(data)
  local sourceFile, sourceLine
  sourceFile, sourceLine = data.sourceFile, data.sourceLine
  if not (sourceFile and sourceLine) then
    return 
  end
  local sourceURL = getSourceURL(sourceFile, sourceLine)
  local sourceLink = sourceURL and "[Line with Context](" .. tostring(sourceURL) .. ")" or ""
  local sourceText = code(tostring(sourceFile) .. ":" .. tostring(sourceLine))
  return tostring(sourceLink) .. "\n" .. tostring(sourceText)
end
local gmodBranch
gmodBranch = function(branch)
  return branch == "unknown" and "main" or branch
end
return {
  bad = bad,
  bold = bold,
  code = code,
  steamIDLink = steamIDLink,
  truncate = truncate,
  timestamp = timestamp,
  getSourceText = getSourceText,
  gmodBranch = gmodBranch
}
