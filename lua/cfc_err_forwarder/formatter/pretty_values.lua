local Round
Round = math.Round
local round
round = function(n)
  return Round(n, 2)
end
local prettyFunc = include("cfc_err_forwarder/formatter/pretty_function.lua")
return function(val)
  local _exp_0 = TypeID(val)
  if TYPE_NIL == _exp_0 then
    return "Nil []"
  elseif TYPE_BOOL == _exp_0 then
    return "Bool [" .. tostring(val) .. "]"
  elseif TYPE_NUMBER == _exp_0 then
    return "Number [" .. tostring(round(val)) .. "]"
  elseif TYPE_STRING == _exp_0 then
    return "\"" .. val .. "\""
  elseif TYPE_TABLE == _exp_0 then
    local count = table.Count(val)
    local countLine = "(empty)"
    if count > 0 then
      local items = "item" .. tostring(count ~= 1 and "s" or "")
      countLine = tostring(count) .. " items"
    end
    return "Table [" .. tostring(countLine) .. "]"
  elseif TYPE_FUNCTION == _exp_0 then
    return "Function [" .. tostring(prettyFunc(val)) .. "]"
  elseif TYPE_VECTOR == _exp_0 then
    return "Vector [" .. tostring(round(val[1])) .. ", " .. tostring(round(val[2])) .. ", " .. tostring(round(val[3])) .. "]"
  elseif TYPE_ANGLE == _exp_0 then
    return "Angle [" .. tostring(round(val[1])) .. ", " .. tostring(round(val[2])) .. ", " .. tostring(round(val[3])) .. "]"
  elseif TYPE_DAMAGEINFO == _exp_0 then
    return "DamageInfo [" .. tostring(round(val:GetDamage())) .. " dmg]"
  elseif TYPE_EFFECTDATA == _exp_0 then
    return "EffectData [" .. tostring(val:GetEntity()) .. "]"
  elseif TYPE_SURFACEINFO == _exp_0 then
    local mat = val:GetMaterial()
    return "SurfaceInfo [" .. tostring(mat and mat:GetName() or [[""]]) .. "]"
  else
    return tostring(val)
  end
end
