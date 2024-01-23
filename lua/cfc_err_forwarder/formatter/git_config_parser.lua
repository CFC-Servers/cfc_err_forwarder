local matchKeyValue
matchKeyValue = function(line)
  return string.match(line, "^%s+(%w+)%s+=%s+(.*)$")
end
local matchNewSection
matchNewSection = function(line, struct)
  line = string.Replace(line, "[", "")
  line = string.Replace(line, "]", "")
  line = string.Replace(line, '"', "")
  local spl = string.Split(line, " ")
  local main = spl[1]
  local sub = spl[2]
  local tbl = struct[main] or { }
  if sub then
    tbl[sub] = { }
  end
  struct[main] = tbl
  if sub then
    return tbl[sub]
  else
    return tbl
  end
end
return function(content)
  local struct = { }
  local lines = string.Split(content, "\n")
  local lineCount = #lines
  local keyvalues
  for i = 1, lineCount do
    local _continue_0 = false
    repeat
      local line = lines[i]
      local trim = string.Trim(line)
      if #trim == 0 then
        _continue_0 = true
        break
      end
      local char = trim[1]
      if char == "#" then
        _continue_0 = true
        break
      end
      if char == "[" then
        keyvalues = matchNewSection(line, struct)
        _continue_0 = true
        break
      end
      local key, value = matchKeyValue(line)
      assert(key)
      keyvalues[key] = value
      _continue_0 = true
    until true
    if not _continue_0 then
      break
    end
  end
  return struct
end
