require "luaerror"
require "reqwest"

errorForwarder = include "cfc_err_forwarder/error_forwarder.lua"
luaerror.EnableCompiletimeDetour true
luaerror.EnableClientDetour true
luaerror.EnableRuntimeDetour true

convarPrefix = "cfc_err_forwarder"
convarFlags = FCVAR_ARCHIVE + FCVAR_PROTECTED
makeConfig = (name, value, help) -> CreateConVar "#{convarPrefix}_#{name}", value, convarFlags, help

export Config = {
    -- cfc_err_forwarder_dedupe_duration
    dedupeDuration: makeConfig "dedupe_duration", "60", "Number of seconds to hold each error before sending it to Discord. Helps de-dupe spammy errors."

    backup: makeConfig "backup", "1", "Whether or not to save errors to a file in case the server crashes or restarts"

    -- cfc_err_forwarder_client_enabled
    clientEnabled: makeConfig "client_enabled", "1", "Whether or not to track and forward Clientside errors"

    webhook:
        -- cfc_err_forwarder_client_webhook
        client: makeConfig "client_webhook", "", "Discord Webhook URL"

        -- cfc_err_forwarder_server_webhook
        server: makeConfig "server_webhook", "", "Discord Webhook URL"
}

local logger
if file.Exists "includes/modules/logger.lua", "LUA"
    require "logger"
    logger = Logger "ErrorForwarder"
else
    log = (...) -> print "[ErrorForwarder]", ...
    log "GM_Logger not found, using backup logger. Consider installing: github.com/CFC-Servers/gm_logger"

    logger =
        trace: ->
        debug: ->
        info: log
        warn: log
        error: log
        
ErrorForwarder = errorForwarder logger, Config

cb = (_, _, value) -> ErrorForwarder\adjustTimer tonumber value
cvars.AddChangeCallback "cfc_err_forwarder_interval", cb, "UpdateTimer"

cb = (_, _, value) -> ErrorForwarder.discord\loadQueue! if value == "1"
cvars.AddChangeCallback "cfc_err_forwarder_backup", cb, "LoadBackupOnEnable"

hook.Add "LuaError", "CFC_ServerErrorForwarder", ErrorForwarder\receiveSVError
hook.Add "ClientLuaError", "CFC_ClientErrorForwarder", ErrorForwarder\receiveCLError
hook.Add "ShutDown", "CFC_ShutdownErrorForwarder", ->
    return unless Config.backup\GetBool!

    logger\info "Shut Down detected, saving unsent queue items..."
    ErrorForwarder\forwardErrors!
    ErrorForwarder.discord\saveQueue!

logger\info "Loaded!"
