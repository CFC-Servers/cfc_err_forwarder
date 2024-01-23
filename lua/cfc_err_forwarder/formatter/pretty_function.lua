local rawget, rawset, tostring, isfunction, istable
do
  local _obj_0 = _G
  rawget, rawset, tostring, isfunction, istable = _obj_0.rawget, _obj_0.rawset, _obj_0.tostring, _obj_0.isfunction, _obj_0.istable
end
functionNameCache = functionNameCache or setmetatable({ }, {
  __mode = "k"
})
local defaultSeen
defaultSeen = function()
  local seen = setmetatable({ }, {
    __mode = "k"
  })
  seen[_G] = true
  if VFS then
    seen[VFS] = true
  end
  if GLib then
    seen[GLib] = true
  end
  if Gooey then
    seen[Gooey] = true
  end
  if GCompute then
    seen[GCompute] = true
  end
  return seen
end
local getNamesFrom
getNamesFrom = function(tbl, path, seen)
  if tbl == nil then
    tbl = _G
  end
  if path == nil then
    path = "_G"
  end
  if seen == nil then
    seen = defaultSeen()
  end
  for k, v in pairs(tbl) do
    local _continue_0 = false
    repeat
      if not (isstring(k)) then
        _continue_0 = true
        break
      end
      if isfunction(v) then
        if rawget(functionNameCache, v) then
          _continue_0 = true
          break
        end
        local newPath = tostring(path) .. "." .. tostring(k)
        rawset(functionNameCache, v, newPath)
        _continue_0 = true
        break
      end
      if istable(v) then
        if rawget(seen, v) then
          _continue_0 = true
          break
        end
        rawset(seen, v, true)
        local newPath = tostring(path) .. "." .. tostring(k)
        getNamesFrom(v, newPath, seen)
      end
      _continue_0 = true
    until true
    if not _continue_0 then
      break
    end
  end
end
hook.Add("InitPostEntity", "CFC_ErrForwarder_FuncNameSetup", getNamesFrom)
return function(func)
  local name = functionNameCache[func]
  name = name and string.Replace(name, "_G.", "")
  if name then
    return name
  end
  local info = debug.getinfo(func, "flLnSu")
  local src = info.short_src or "<unknown source>"
  src = string.Replace(src, "addons/", "")
  return "\n  " .. tostring(src) .. ":" .. tostring(info.linedefined) .. "\n"
end
