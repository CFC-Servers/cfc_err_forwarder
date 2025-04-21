-- Stores the functions "dot path" by the function itself
_G._ErrorForwarder_functionNameCache = _G._ErrorForwarder_functionNameCache or {}
local functionNameCache = _G._ErrorForwarder_functionNameCache

-- Stores the functions "dot path" by it's source file and line number
_G._ErrorForwarder_functionPathNameCache = _G._ErrorForwarder_functionPathNameCache or {}
local functionPathNameCache = _G._ErrorForwarder_functionPathNameCache

-- TODO: Expand this to allow sub-table ignoring
local defaultSeen = function()
    local seen = setmetatable( {}, { __mode = "k" } )
    seen[seen] = true

    if VFS then seen[VFS] = true end
    if Glib then seen[GLib] = true end
    if Gooey then seen[Gooey] = true end
    if Gcompute then seen[GCompute] = true end

    return seen
end

local getNamesFrom
do
    local isstring = isstring
    local istable = istable
    local isfunction = isfunction
    local debug_getinfo = debug.getinfo
    local string_format = string.format

    local function storePath( func, dotPath )
        local info = debug_getinfo( func, "S" )
        local source = info.short_src

        if not source then return end

        local path = string_format( "%s:%s", source, info.linedefined )
        functionPathNameCache[path] = dotPath
    end

    getNamesFrom = function( tbl, path, seen )
        tbl = tbl or _G
        path = path or "_G"
        seen = seen or defaultSeen()

        for k, v in pairs( tbl ) do
            if isstring( k ) then
                if isfunction( v ) then
                    if not functionNameCache[v] then
                        local newPath = path .. "." .. k
                        storePath( v, newPath )
                        functionNameCache[v] = newPath
                    end
                elseif istable( v ) then
                    if not seen[v] then
                        seen[v] = true
                        local newPath = path .. "." .. k
                        getNamesFrom( v, newPath, seen )
                    end
                end
            end
        end
    end
end

hook.Add( "InitPostEntity", "CFC_ErrForwarder_FuncNameSetup", function()
    if not ErrorForwarder.HasLuaErrorDLL then return end

    local startTime = SysTime()
    ProtectedCall( getNamesFrom )
    print( "[CFC_ErrForwarder] Function name cache built in " .. SysTime() - startTime .. " seconds. Disable with convar: cfc_err_forwarder_enable_name_cache" )
end )

do
    local debug_getinfo = debug.getinfo
    local string_format = string.format
    local string_Replace = string.Replace

    local prettyFunction = {}

    --- Get a pretty name for a function defined in a file
    --- @param path string
    --- @param line number
    --- @return string
    function prettyFunction.FromFile( path, line )
        if not ( path and line ) then return "<unknown>" end

        if path == "[C]" then
            return "[C]"
        end

        local name = functionPathNameCache[funcOrPath]
        return name or "<unknown>"
    end

    --- Get a pretty name for a function (returns the path:line if the function is not named)
    --- @param func function
    --- @return string
    function prettyFunction.FromFunction( func )
        if not func then return "<unknown>" end

        local name = functionNameCache[func]
        name = name and string_Replace( name, "_G.", "" )
        if name then return name end

        local info = debug_getinfo( func, "flLnSu" )
        local src = info.short_src or "<unknown source>"
        src = string_Replace( src, "addons/", "" )

        return string_format( "%s:%s", src, info.linedefined )
    end

    return prettyFunction
end
