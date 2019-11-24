ErrorForwarder = include "cfc_err_forwarder/error_forwarder.lua"

require "luaerror"
luaerror.EnableCompiletimeDetour true
luaerror.EnableRuntimeDetour true

addon_name = "CFC Error Forwarder"

init = ->
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

dependencies_loaded = ->
    CFCLogger != nil and WebhookerInterface != nil

if dependencies_loaded! then return init!

waiter_loaded = -> Waiter != nil

on_timeout = -> error "[#{addon_name}] [FATAL] Dependencies didn't load in time! Couldn't load!"

if waiter_loaded!
    Waiter.waitFor dependencies_loaded, init, on_timeout
else
    export WaiterQueue
    WaiterQueue or= {}

    struct = {
        waitingFor: dependencies_loaded,
        onSuccess: init,
        onTimeout: on_timeout
    }

    table.insert WaiterQueue, struct
