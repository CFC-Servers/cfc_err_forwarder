local MAX_LOCALS = 8
return function(data)
  local locals
  local stack
  stack = data.stack
  for _index_0 = 1, #stack do
    local _continue_0 = false
    repeat
      local level = stack[_index_0]
      if locals then
        _continue_0 = true
        break
      end
      if not (level) then
        _continue_0 = true
        break
      end
      locals = level.locals
      _continue_0 = true
    until true
    if not _continue_0 then
      break
    end
  end
  if not (locals) then
    return 
  end
  if table.Count(locals) == 0 then
    return 
  end
  local out = { }
  local longest = 0
  for name, value in pairs(locals) do
    if #name > longest then
      longest = #name
    end
    table.insert(out, {
      name = name,
      value = value
    })
  end
  local convert
  convert = function(line)
    local name, value
    name, value = line.name, line.value
    local spacing = string.rep(" ", longest - #name)
    return tostring(name) .. " " .. tostring(spacing) .. "= " .. tostring(value)
  end
  local maxLocals = math.min(MAX_LOCALS, #out)
  do
    local _accum_0 = { }
    local _len_0 = 1
    local _max_0 = maxLocals
    for _index_0 = 1, _max_0 < 0 and #out + _max_0 or _max_0 do
      local line = out[_index_0]
      _accum_0[_len_0] = convert(line)
      _len_0 = _len_0 + 1
    end
    out = _accum_0
  end
  return table.concat(out, "\n")
end
