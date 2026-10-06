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

    -- Clientside error forwarding
    util.AddNetworkString( "cfc_errorforwarder_clienterror" )
    net.Receive( "cfc_errorforwarder_clienterror", function( _, ply )
        if not Config.clientEnabled:GetBool() then return end

        if ply.ErrorForwarder_LastReceiveTime and ply.ErrorForwarder_LastReceiveTime > os.time() - 10 then return end
        ply.ErrorForwarder_LastReceiveTime = os.time()

        local err = net.ReadString()
        local addonTitle = net.ReadString()
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

        receiver( ply, err, firstEntry.File, firstEntry.Line, err, newStack, addonTitle )
    end )
end
