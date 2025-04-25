local Forwarder = ErrorForwarder.Forwarder
local Config = ErrorForwarder.Config

--- @param plyOrIsRuntime boolean|Player
--- @param fullError string
--- @param sourceFile string?
--- @param sourceLine number?
--- @param errorString string?
--- @param stack DebugInfoStruct
local function receiver( plyOrIsRuntime, fullError, sourceFile, sourceLine, errorString, stack )
    --- @class ErrorForwarder_LuaError
    local luaError = {
        fullError = fullError,
        sourceFile = sourceFile,
        sourceLine = sourceLine,
        errorString = errorString,
        stack = stack,
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

    hook.Add( "OnLuaError", "CFC_RuntimeErrorForwarder", function( err, _, stack )
        -- Skip this if we're using gm_luaerror and are configured to use it
        if ErrorForwarder.HasLuaErrorDLL and Config.useLuaErrorBinary:GetBool() then return end

        local newStack = convertStack( stack --[[@as GmodOnLuaErrorStack]] )

        local firstEntry = stack[1] or {}
        local fileName = firstEntry.File or "Unknown"
        local fileLine = firstEntry.Line or 0
        receiver( true, err, fileName, fileLine, err, newStack )
    end )

        -- Clientside error forwarding
    util.AddNetworkString( "cfc_errorforwarder_clienterror" )
    net.Receive( "cfc_errorforwarder_clienterror", function( _, ply )
        if not Config.clientEnabled:GetBool() then return end

        if ply.ErrorForwarder_LastReceiveTime and ply.ErrorForwarder_LastReceiveTime > os.time() - 10 then return end
        ply.ErrorForwarder_LastReceiveTime = os.time()

        local err = net.ReadString()
        local stackSize = net.ReadUInt( 4 )
        local stack = {}
        for _ = 1, stackSize do
            local fileName = net.ReadString()
            local funcName = net.ReadString()
            local line = net.ReadInt( 16 )

            table.insert( stack, {
                File = fileName,
                Function = funcName,
                Line = line,
            } )
        end

        if #stack == 0 then return end

        local newStack = convertStack( stack --[[@as GmodOnLuaErrorStack]] )
        local firstEntry = stack[1]
        if not firstEntry then return end

        receiver( ply, err, firstEntry.File, firstEntry.Line, err, newStack )
    end )
end

-- gm_luaerror hooks
if ErrorForwarder.HasLuaErrorDLL then
    hook.Add( "LuaError", "CFC_ServerErrorForwarder", function( ... )
        if Config.useLuaErrorBinary:GetBool() == false then return end
        receiver( ... )
    end )
end
