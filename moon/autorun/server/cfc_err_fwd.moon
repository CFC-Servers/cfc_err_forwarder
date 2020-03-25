ErrorForwarder = include "cfc_err_forwarder/error_forwarder.lua"

require "luaerror"
require "cfclogger"
require "webhooker_interface"

luaerror.EnableCompiletimeDetour true
luaerror.EnableRuntimeDetour true

addon_name = "CFC Error Forwarder"

logger = CFCLogger addon_name
webhooker_interface = WebhookerInterface!

alert_discord = (message) ->
    data = {addon: addon_name, :message}
    webhooker_interface\send "runtime-error", data

logger\on("error")\call(alert_discord)
logger\info "Logger Loaded!"

groom_interval = 60 -- in seconds
error_forwarder = ErrorForwarder logger, webhooker_interface, groom_interval

hook.Remove "LuaError", "CFC_ServerErrorForwarder"
hook.Add "LuaError", "CFC_ServerErrorForwarder", error_forwarder\receive_sv_lua_error

hook.Remove "ClientLuaError", "CFC_ClientErrorForwarder"
hook.Add "ClientLuaError", "CFC_ClientErrorForwarder", error_forwarder\receive_cl_lua_error

timer_name = "CFC_ErrorForwarderQueue"

timer.Remove timer_name
timer.Create timer_name, groom_interval, 0, error_forwarder\groom_queue
