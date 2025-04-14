require( "formdata" )
include( "logger.lua" )
include( "helpers.lua" )

--- @class ErrorForwarder
local EF = ErrorForwarder
local log = EF.Logger
local colors = EF.colors
local os_time = os.time

if util.IsBinaryModuleInstalled( "luaerror" ) then
    require( "luaerror" )
    luaerror.EnableCompiletimeDetour( true )
    luaerror.EnableRuntimeDetour( true )
end

if util.IsBinaryModuleInstalled( "reqwest" ) then
    require( "reqwest" )
else
    log.err( "Reqwest module is not installed!" )
    log.warn( "This addon cannot function without the Reqwest module, as Discord blocks Gmod's base HTTP Agent." )
    log.warn( "Please visit this page and download the latest version of the module for your system ", colors.debug, "(then place it in lua/bin/):" )
    log.info( colors.highlight, "https://github.com/WilliamVenner/gmsv_reqwest/releases" )

    error( "ErrorForwarder: Cannot Load! Reqwest module is not installed! (More info in logs)" )
end

local makeConfig
do
    local prefix = "cfc_err_forwarder"
    local flags = FCVAR_ARCHIVE + FCVAR_PROTECTED
    makeConfig = function( name, value, help )
        return CreateConVar( prefix .. "_" .. name, value, flags, help )
    end
end

EF.Config = {
    -- cfc_err_forwarder_interval
    groomInterval = makeConfig( "interval", "60", "Interval at which errors are parsed and sent to Discord" ),

    -- cfc_err_forwarder_backup
    backup = makeConfig( "backup", "1", "Whether or not to save errors to a file in case the server crashes or restarts" ),

    -- cfc_err_forwarder_client_enabled
    clientEnabled = makeConfig( "client_enabled", "1", "Whether or not to track and forward Clientside errors (Only relevant for gm_luaerror)" ),

    -- cfc_err_forwarder_include_full_context
    includeFullContext = makeConfig( "include_full_context", "0", "Whether or not to include JSON files in every message containing the full locals/upvalues (Only relevant for gm_luaerror)" ),

    -- cfc_err_forwarder_enable_name_cache
    buildNameCache = makeConfig( "enable_name_cache", "1", "Whether or not to build a friendly name cache for all functions in the global scope. This can impact startup times. (Only relevant for gm_luaerror)" ),

    -- cfc_err_forwarder_use_gm_luaerror
    useLuaErrorBinary = makeConfig( "use_gm_luaerror", "1", "Whether or not to use the gm_luaerror DLL if it's present." ),

    webhook = {
        -- cfc_err_forwarder_client_webhook
        client = makeConfig( "client_webhook", "", "Discord Webhook URL" ),

        -- cfc_err_forwarder_server_webhook
        server = makeConfig( "server_webhook", "", "Discord Webhook URL" )
    }
}
local Config = EF.Config

include( "discord_interface.lua" )
include( "error_forwarder.lua" )
include( "branch.lua" )

local Discord = EF.Discord
local Forwarder = EF.Forwarder

cvars.AddChangeCallback( Config.backup:GetName(), function( _, _, new )
    if new ~= "1" then return end
    EF.Discord:LoadQueue()
end, "UpdateBackup" )


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
        occurredAt = os_time()
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
        if luaerror and Config.useLuaErrorBinary:GetBool() then return end

        local newStack = convertStack( stack --[[@as GmodOnLuaErrorStack]] )

        local firstEntry = stack[1]
        receiver( true, err, firstEntry.File, firstEntry.Line, err, newStack )
    end )

        -- Clientside error forwarding
    util.AddNetworkString( "cfc_errorforwarder_clienterror" )
    net.Receive( "cfc_errorforwarder_clienterror", function( _, ply )
        if not Config.clientEnabled:GetBool() then return end

        if ply.ErrorForwarder_LastReceiveTime and ply.ErrorForwarder_LastReceiveTime > os_time() - 10 then return end
        ply.ErrorForwarder_LastReceiveTime = os_time()

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
hook.Add( "LuaError", "CFC_ServerErrorForwarder", function( ... )
    if Config.useLuaErrorBinary:GetBool() == false then return end
    receiver( ... )
end )

hook.Add( "ShutDown", "CFC_ShutdownErrorForwarder", function()
    log.warn( "Shut Down detected, saving unsent queue items..." )
    Forwarder:ForwardErrors()

    if not Config.backup:GetBool() then return end
    Discord:saveQueue()
end )

log.info( "Loaded!" )
