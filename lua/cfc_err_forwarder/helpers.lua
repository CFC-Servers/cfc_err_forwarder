local fmt = string.format

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

