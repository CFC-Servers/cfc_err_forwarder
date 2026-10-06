local Forwarder = ErrorForwarder.Forwarder
local Config = ErrorForwarder.Config

--- @param plyOrIsRuntime boolean|Player
--- @param fullError string
--- @param sourceFile string?
--- @param sourceLine number?
--- @param errorString string?
--- @param stack DebugInfoStruct
--- @param addonTitle string?
local function receiver( plyOrIsRuntime, fullError, sourceFile, sourceLine, errorString, stack, addonTitle )
    --- @class ErrorForwarder_LuaError
    local luaError = {
        fullError = fullError,
        sourceFile = sourceFile,
        sourceLine = sourceLine,
        errorString = errorString,
        stack = stack,
        addonTitle = addonTitle,
        occurredAt = os.time()
    }

    if isbool( plyOrIsRuntime ) then
        luaError.isRuntime = plyOrIsRuntime
    else
        luaError.isRuntime = true
        luaError.ply = plyOrIsRuntime
    end

    Forwarder:QueueError( luaError )
end

do -- Base game error hooks
    --- Converts a stack from the base game OnLuaError and converts it to the standard debug stackinfo
    --- @param luaHookStack GmodOnLuaErrorStack
    local function convertStack( luaHookStack )
        --- @type DebugInfoStruct[]
        local newStack = {}

        for i = 1, #luaHookStack do
            local item = luaHookStack[i]

            --- @type DebugInfoStruct
            local newItem = {
                source = item.File,
                funcName = item.Function,
                currentline = item.Line,
                name = item.Function,
            }

            table.insert( newStack, newItem )
        end

        return newStack
    end

    hook.Add( "OnLuaError", "CFC_RuntimeErrorForwarder", function( err, _, stack, addonTitle )
        local newStack = convertStack( stack --[[@as GmodOnLuaErrorStack]] )

        local firstEntry = stack[1] or {}
        local fileName = firstEntry.File or "Unknown"
        local fileLine = firstEntry.Line or 0
        receiver( true, err, fileName, fileLine, err, newStack, addonTitle )
    end )

    hook.Add( "OnClientLuaError", "CFC_RuntimeErrorForwarder", function( err, ply, stack, addonTitle )
        if not Config.clientEnabled:GetBool() then return end

        local firstEntry = stack[1]
        if not firstEntry then return end

        local newStack = convertStack( stack --[[@as GmodOnLuaErrorStack]] )
        receiver( ply, err, firstEntry.File, firstEntry.Line, err, newStack, addonTitle ~= "ERROR" and addonTitle )
    end )
end
