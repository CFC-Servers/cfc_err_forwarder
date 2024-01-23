local clientColor = 14592265
local serverColor = 240116
local locals = include("locals.lua")
local niceStack = include("nice_stack.lua")
local bad, bold, getSourceText, code, steamIDLink, truncate, timestamp, gmodBranch
do
  local _obj_0 = include("text_helpers.lua")
  bad, bold, getSourceText, code, steamIDLink, truncate, timestamp, gmodBranch = _obj_0.bad, _obj_0.bold, _obj_0.getSourceText, _obj_0.code, _obj_0.steamIDLink, _obj_0.truncate, _obj_0.timestamp, _obj_0.gmodBranch
end
local nonil
nonil = function(t)
  local _accum_0 = { }
  local _len_0 = 1
  for _index_0 = 1, #t do
    local v = t[_index_0]
    if v ~= nil then
      _accum_0[_len_0] = v
      _len_0 = _len_0 + 1
    end
  end
  return _accum_0
end
return function(data)
  local client = data.isClientside
  local realm = client and "Client" or "Server"
  return {
    content = "",
    embeds = {
      {
        color = client and clientColor or serverColor,
        title = tostring(realm) .. " Error",
        author = {
          name = GetHostName()
        },
        description = bad(data.errorString),
        fields = nonil({
          (function()
            do
              local source = getSourceText(data)
              if source then
                return {
                  name = "Source File",
                  value = source
                }
              end
              return nil
            end
          end)(),
          {
            name = "Full Error",
            value = code(truncate(niceStack(data)))
          },
          (function()
            do
              local l = locals(data)
              if l then
                return {
                  name = "Locals",
                  value = code(truncate(l), "m")
                }
              end
              return nil
            end
          end)(),
          (function()
            do
              local _with_0 = data
              local ply, plyName, plySteamID
              ply, plyName, plySteamID = _with_0.ply, _with_0.plyName, _with_0.plySteamID
              if ply then
                return {
                  name = "Player",
                  value = bold(tostring(plyName) .. " ( " .. tostring(steamIDLink(plySteamID)) .. " )")
                }
              end
              return nil
            end
          end)(),
          (function()
            do
              local _with_0 = data
              local branch
              branch = _with_0.branch
              if branch then
                return {
                  name = "Branch",
                  value = bold("`" .. tostring(gmodBranch(branch)) .. "`", {
                    inline = true
                  })
                }
              end
              return nil
            end
          end)(),
          {
            name = "Count",
            value = bold(data.count),
            inline = true
          },
          {
            name = "Most recent occurrence",
            value = timestamp(data.occurredAt),
            inline = true
          }
        })
      }
    }
  }
end
