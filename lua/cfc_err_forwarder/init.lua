include( "cfc_err_forwarder/helpers.lua" )

local EF = ErrorForwarder
local log = EF.Logger

local os_time = os.time

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
    clientEnabled = makeConfig( "client_enabled", "1", "Whether or not to track and forward Clientside errors" ),

    includeFullContext = makeConfig( "include_full_context", "0", "Whether or not to include JSON files in every message containing the full locals/upvalues" ),

    webhook = {
        -- cfc_err_forwarder_client_webhook
        client = makeConfig( "client_webhook", "", "Discord Webhook URL" ),

        -- cfc_err_forwarder_server_webhook
        server = makeConfig( "server_webhook", "", "Discord Webhook URL" )
    }
}
local Config = EF.Config

include( "cfc_err_forwarder/discord_interface.lua" )
include( "cfc_err_forwarder/error_forwarder.lua" )
include( "cfc_err_forwarder/branch.lua" )
local Discord = EF.Discord
local Forwarder = EF.Forwarder

cvars.AddChangeCallback( Config.groomInterval:GetName(), function( _, _, new )
    Forwarder:adjustTimer( new )
end, "UpdateTimer" )

cvars.AddChangeCallback( Config.backup:GetName(), function( _, _, new )
    if new ~= "1" then return end
    EF.Discord:LoadQueue()
end, "UpdateBackup" )


--- @param plyOrIsRuntime boolean|Player
--- @param fullError string
--- @param sourceFile string?
--- @param sourceLine number?
--- @param errorString string?
--- @param stack table
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

hook.Add( "LuaError", "CFC_ServerErrorForwarder", receiver )
hook.Add( "ClientLuaError", "CFC_ClientErrorForwarder", receiver )
hook.Add( "ShutDown", "CFC_ShutdownErrorForwarder", function()
    log.warn( "Shut Down detected, saving unsent queue items..." )
    Forwarder:ForwardErrors()

    if Config.backup:GetInt() ~= 1 then return end
    Discord:saveQueue()
end )

log.info( "Loaded!" )
