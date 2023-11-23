local table_concat = table.concat
local table_insert = table.insert
local string_format = string.format

local GetSource = include( "get_source_url.lua" )

local function formatStackInfo( stack )
    local lines = {}

    for i = 1, #stack do
        local item = stack[i]

        local lineNumber = item.currentline
        local src = item.short_src or item.source or "<unknown source>"

        local name = item.name or ""
        name = #name == 0 and "<unknown>" or name

        local sourceInfo = src .. ":" .. lineNumber

        local link = GetSource( src, lineNumber )
        if link then
            sourceInfo = string_format( "[`%s`](%s)", sourceInfo, link )

            if #sourceInfo <= 54 then
                -- <unknown> → [`addons/cfc_erf_forwarder/lua/autorun/cfc_err_fwd.lua:2`](https://blah)
                table_insert( lines, string_format( "%s. **%s** → %s", i, name, sourceInfo ) )
            else
                -- Nicely break to a newline if it's going to do it anyway
                -- <unknown>
                --   └ [`addons/cfc_erf_forwarder/lua/autorun/cfc_err_fwd.lua:2`](https://blah)
                table_insert( lines, string_format( "%s. **%s**\n  └ %s", i, name, sourceInfo ) )
            end
        else
            -- __newindex → `[C]:-1`
            sourceInfo = string_format( "`%s`", sourceInfo )
            table_insert( lines, string_format( "%s. **%s** → %s", i, name, sourceInfo ) )
        end
    end

    return table_concat( lines, "\n" )
end

local linePattern = [[^%d+%. (%w+) %- ([%w/%.]+):(%d+)$]]
local function extractLineInfo( line )
    line = string.TrimLeft( line, " " )

    local name, sourceFile, sourceLine = string.match( line, linePattern )
    if not name then return end

    return {
        currentline = sourceLine,
        name = name,
        short_src = sourceFile
    }
end

local function convertStringStack( stack )
    print( "I AM CONVERTING THE STACK" )
    -- If it doesn't contain any actual stack info, just return the whole string
    if not string.find( stack, "1.", 1, true ) then
        return "```lua" .. stack .. "\n```"
    end

    local lines = {}
    local stackLines = string.Split( stack, "\n" )

    for i = 1, #stackLines do
        local line = stackLines[i]
        local info = extractLineInfo( line )
        if info then
            table.insert( lines, info )
        end
    end

    return lines
end

return function( data )
    return formatStackInfo( data.luaError.stack )

    -- if istable( data ) then
    --     stack = data.luaError.stack
    --     if table.IsEmpty( stack ) then
    --     end
    -- else
    --     assert( isstring( data ), "Given stack wasn't a string or a table, it was: " .. type( data ) )
    --     stack = convertStringStack( data )

    --     -- If it couldn't be converted into stack info, just return the formatted string
    --     if isstring( stack ) then
    --         return stack
    --     end
    -- end

    -- return formatStackInfo( stack )
end
