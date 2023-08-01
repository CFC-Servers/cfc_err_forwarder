require "luaerror"
require "reqwest"

timerName = "CFC_ErrorForwarderQueue"
errorForwarder = include "cfc_err_forwarder/error_forwarder.lua"
discordBuilder = include "cfc_err_forwarder/discord_interface.lua"

luaerror.EnableCompiletimeDetour true
luaerror.EnableClientDetour true
luaerror.EnableRuntimeDetour true

convarPrefix = "cfc_err_forwarder"
convarFlags = FCVAR_ARCHIVE + FCVAR_PROTECTED
makeConfig = (name, value, help) -> CreateConVar "#{convarPrefix}_#{name}", value, convarFlags, help

Config =
    -- cfc_err_forwarder_interval
    groomInterval: makeConfig "interval", "60", "Interval at which errors are parsed and sent to Discord"

    -- cfc_err_forwarder_client_enabled
    clientEnabled: makeConfig "client_enabled", "1", "Whether or not to track and forward Clientside errors"

    webhook:
        -- cfc_err_forwarder_client_webhook
        client: makeConfig "client_webhook", "", "Discord Webhook URL"

        -- cfc_err_forwarder_server_webhook
        server: makeConfig "server_webhook", "", "Discord Webhook URL"

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
        

Discord = discordBuilder Config
ErrorForwarder = errorForwarder logger, Discord, Config


timer.Create timerName, Config.groomInterval\GetInt! or 60, 0, ->
    success, err = pcall ErrorForwarder\groomQueue
    logger\error "Groom Queue failed!", err if not success

cvars.AddChangeCallback "cfc_err_forwarder_interval", (_, _, value) ->
    timer.Adjust timerName, tonumber(value), "UpdateTimer"

hook.Add "LuaError", "CFC_ServerErrorForwarder", ErrorForwarder\receiveSVError
hook.Add "ClientLuaError", "CFC_ClientErrorForwarder", ErrorForwarder\receiveCLError
hook.Add "ShutDown", "CFC_ShutdownErrorForwarder", ErrorForwarder\forwardErrors

net.Receive "cfc_err_forwarder_clbranch", (_,ply) ->
    if not ply.CFC_ErrorForwarder_CLBranch
        ply.CFC_ErrorForwarder_CLBranch = net.ReadString!

logger\info "Loaded!"
