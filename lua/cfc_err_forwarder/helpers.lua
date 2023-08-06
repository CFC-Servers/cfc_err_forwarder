local istable = istable
local tostring = tostring
local pretty = include( "cfc_err_forwarder/formatter/pretty_values.lua" )

ErrorForwarder.Helpers = {}
--- @class ErrForwarder_Helpers
local Helpers = ErrorForwarder.Helpers

--- Strips the upvalues and activelines from all levels of the given stack table
--- @param tbl table
function Helpers.StripStack( tbl )
    for _, obj in pairs( tbl ) do
        obj.upvalues = nil
        obj.activeLines = nil
    end
end

do
    --- Converts a table to stringified table
    --- @param tbl table
    --- @return string
    local function stringTable( tbl )
        local oneline = table.Count( tbl ) == 1

        local str = "{"
        if not oneline then
            str = str .. "\n"
        end

        local count = 0
        for k, v in pairs( tbl ) do
            if count >= 8 then break end

            str = str .. "  " .. tostring( k ) .. " = " .. pretty( v )
            str = str .. ( oneline and " " or "\n" )

            count = count + 1
        end

        return str .. "}"
    end

    local function saveLocal( newLocals, name, value )
        if istable( value ) then
            newLocals[name] = stringTable( value )
        else
            local val = pretty( value )

            if #val > 125 then
                if val[1] == '"' then
                    val = string.sub( newLocal, 1, 121 ) .. "...\""
                else
                    val = string.sub( newLocal, 1, 122 ) .. "..."
                end
            end

            newLocals[name] = val
        end
    end

    --- Formats all of the locals in the given stack table
    --- @param stack table
    function Helpers.SaveLocals( stack )
        for _, stackObj in pairs( stack ) do
            local locals = stackObj.locals

            if locals then
                local newLocals = {}
                for name, value in pairs( locals ) do
                    saveLocal( newLocals, name, value )
                end
            end
        end
    end
end
