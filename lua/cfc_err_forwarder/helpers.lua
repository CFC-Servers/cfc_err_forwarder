local istable = istable
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
    local function saveLocal( newLocals, name, value )
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

    --- Formats all of the locals in the given stack table
    --- @param stack table
    function Helpers.SaveLocals( stack )
        for _, stackObj in pairs( stack ) do
            local locals = stackObj.locals

            if locals then
                local newLocals = {}
                for name, value in pairs( locals ) do
                    print( "Saving local:", name, value )
                    saveLocal( newLocals, name, value )
                end
            end
        end
    end
end
