local tostring = tostring

local math_Round = math.Round
local round = function( n ) return math_Round( n, 2 ) end
local prettyFunc = include( "cfc_err_forwarder/formatter/pretty_function.lua" )

return function( val )
    local typeID = TypeID( val )

    if typeID == TYPE_NIL then
        return "Nil []"
    elseif typeID == TYPE_BOOL then
        return string.format( "Bool [%s]", val and "true" or "false" )
    elseif typeID == TYPE_NUMBER then
        return string.format( "Number [%s]", round( val ) )
    elseif typeID == TYPE_STRING then
        return string.format( [["%s"]], val )
    elseif typeID == TYPE_TABLE then
        local count = table.Count( val )
        local countLine = "(empty)"

        if count > 0 then
            local items = "item" .. ( count ~= 1 and "s" or "" )
            countLine = count .. " " .. items
        end

        return string.format( "Table [%s]", countLine )
    elseif typeID == TYPE_FUNCTION then
        return string.format( "Function [%s]", prettyFunc( val ) )
    elseif typeID == TYPE_VECTOR then
        return string.format( "Vec [%s, %s, %s]", round( val[1] ), round( val[2] ), round( val[3] ) )
    elseif typeID == TYPE_ANGLE then
        return string.format( "Ang [%s, %s, %s]", round( val[1] ), round( val[2] ), round( val[3] ) )
    elseif typeID == TYPE_DAMAGEINFO then
        return string.format( "DamageInfo [%s dmg]", val:GetDamage() )
    elseif typeID == TYPE_EFFECTDATA then
        return string.format( "EffectData [%s:%s]", val:GetEffectName(), val:GetEntity() )
    elseif typeID == TYPE_SURFACEINFO then
        local mat = val:GetMaterial()
        return string.format( "SurfaceInfo [%s]", mat and mat:GetName() or [[""]] )
    else
        return tostring( val )
    end
end
