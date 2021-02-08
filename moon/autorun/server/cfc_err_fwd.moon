require "luaerror"
require "cfclogger"
require "webhooker_interface"

ErrorForwarder = include "cfc_err_forwarder/error_forwarder.lua"

luaerror.EnableCompiletimeDetour true
luaerror.EnableRuntimeDetour true

ADDON_NAME = "CFC Error Forwarder"
GROOM_INTERVAL = 60 -- in seconds

logger = CFCLogger ADDON_NAME
webhooker = WebhookerInterface!

alertDiscord = (message) ->
    data = {addon: ADDON_NAME, :message}
    webhooker\send "runtime-error", data

logger\on("error")\call(alertDiscord)
logger\info "Logger Loaded!"

errorForwarder = ErrorForwarder logger, webhooker, GROOM_INTERVAL

hook.Add "LuaError", "CFC_ServerErrorForwarder",  (...) -> errorForwarder\receiveSVError(...)
hook.Add "ClientLuaError", "CFC_ClientErrorForwarder", (...) -> errorForwarder\receiveCLError(...)

timerName = "CFC_ErrorForwarderQueue"
timer.Create timerName, GROOM_INTERVAL, 0, errorForwarder\groomQueue
