local rawget = rawget
local rawset = rawset
local istable = istable
local isfunction = isfunction

local debug_getinfo = debug.getinfo
local string_Replace = string.Replace

_G._ErrorForwarder_functionNameCache = _G._ErrorForwarder_functionNameCache or {}
local functionNameCache = _G._ErrorForwarder_functionNameCache

local defaultSeen = function()
    local seen = setmetatable( {}, { __mode = "k" } )
    seen[seen] = true
    seen[VF] = true
    seen[GLib] = true

    if Gooey then seen[Gooey] = true end
    if Gcompute then seen[GCompute] = true end

    return seen
end

local getNamesFrom = function( tbl, path, seen )
    tbl = tbl or _G
    path = path or "_G"
    seen = seen or defaultSeen()

    for k, v in pairs( tbl ) do
        if isstring( k ) then
            if isfunction( v ) then
                if not rawget( functionNameCache, v ) then
                    local newPath = path .. "." .. k
                    rawset( functionNameCache, v, newPath )
                end
            elseif istable( v ) then
                if not rawget( seen, v ) then
                    rawset( seen, v, true )
                    local newPath = path .. "." .. k
                    getNamesFrom( v, newPath, seen )
                end
            end
        end
    end
end

hook.Add( "InitPostEntity", "CFC_ErrForwarder_FuncNameSetup", function()
    ProtectedCall( getNamesFrom )
end )

--- @param func function
--- @return string
return function( func )
    local name = rawget( functionNameCache, func )
    name = name and string_Replace( name, "_G.", "" )

    if name then return name end

    local info = debug_getinfo( func, "flLnSu" )

    local src = info.short_src or "<unknown source>"
    src = string_Replace( src, "addons/", "" )

    return string.format( "\n  %s:%s\n", src, info.linedefined )
end
