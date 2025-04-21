local function makeConfig( name, value, help )
    return CreateConVar( "cfc_err_forwarder_" .. name, value, FCVAR_ARCHIVE + FCVAR_PROTECTED, help )
end

ErrorForwarder.Config = {
    -- cfc_err_forwarder_interval
    groomInterval = makeConfig( "interval", "60", "Interval at which errors are parsed and sent to Discord" ),

    -- cfc_err_forwarder_backup
    backup = makeConfig( "backup", "1", "Whether or not to save errors to a file in case the server crashes or restarts" ),

    -- cfc_err_forwarder_client_enabled
    clientEnabled = makeConfig( "client_enabled", "1", "Whether or not to track and forward Clientside errors (Only relevant for gm_luaerror)" ),

    -- cfc_err_forwarder_include_full_context
    includeFullContext = makeConfig( "include_full_context", "0", "Whether or not to include JSON files in every message containing the full locals/upvalues (Only relevant for gm_luaerror)" ),

    -- cfc_err_forwarder_use_gm_luaerror
    useLuaErrorBinary = makeConfig( "use_gm_luaerror", "1", "Whether or not to use the gm_luaerror DLL if it's present." ),

    webhook = {
        -- cfc_err_forwarder_client_webhook
        client = makeConfig( "client_webhook", "", "Discord Webhook URL" ),

        -- cfc_err_forwarder_server_webhook
        server = makeConfig( "server_webhook", "", "Discord Webhook URL" )
    }
}

cvars.AddChangeCallback( ErrorForwarder.Config.backup:GetName(), function( _, _, new )
    if new ~= "1" then return end
    ErrorForwarder.Discord:LoadQueue()
end, "UpdateBackup" )
