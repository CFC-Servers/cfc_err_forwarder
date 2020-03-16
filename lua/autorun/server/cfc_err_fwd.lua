local ErrorForwarder = include("cfc_err_forwarder/error_forwarder.lua")
require("luaerror")
require("cfclogger")
luaerror.EnableCompiletimeDetour(true)
luaerror.EnableRuntimeDetour(true)
local addon_name = "CFC Error Forwarder"
local init
init = function()
  local logger = CFCLogger(addon_name)
  local webhooker_interface = WebhookerInterface()
  local alert_discord
  alert_discord = function(message)
    local data = {
      addon = addon_name,
      message = message
    }
    return webhooker_interface:send("runtime-error", data)
  end
  logger:on("error"):call(alert_discord)
  logger:info("Logger Loaded!")
  local groom_interval = 60
  local error_forwarder = ErrorForwarder(logger, webhooker_interface, groom_interval)
  hook.Remove("LuaError", "CFC_ServerErrorForwarder")
  hook.Add("LuaError", "CFC_ServerErrorForwarder", (function()
    local _base_0 = error_forwarder
    local _fn_0 = _base_0.receive_sv_lua_error
    return function(...)
      return _fn_0(_base_0, ...)
    end
  end)())
  hook.Remove("ClientLuaError", "CFC_ClientErrorForwarder")
  hook.Add("ClientLuaError", "CFC_ClientErrorForwarder", (function()
    local _base_0 = error_forwarder
    local _fn_0 = _base_0.receive_cl_lua_error
    return function(...)
      return _fn_0(_base_0, ...)
    end
  end)())
  local timer_name = "CFC_ErrorForwarderQueue"
  timer.Remove(timer_name)
  return timer.Create(timer_name, groom_interval, 0, (function()
    local _base_0 = error_forwarder
    local _fn_0 = _base_0.groom_queue
    return function(...)
      return _fn_0(_base_0, ...)
    end
  end)())
end
local dependencies_loaded
dependencies_loaded = function()
  return CFCLogger ~= nil and WebhookerInterface ~= nil
end
if dependencies_loaded() then
  return init()
end
local waiter_loaded
waiter_loaded = function()
  return Waiter ~= nil
end
local on_timeout
on_timeout = function()
  return error("[" .. tostring(addon_name) .. "] [FATAL] Dependencies didn't load in time! Couldn't load!")
end
if waiter_loaded() then
  return Waiter.waitFor(dependencies_loaded, init, on_timeout)
else
  WaiterQueue = WaiterQueue or { }
  local struct = {
    waitingFor = dependencies_loaded,
    onSuccess = init,
    onTimeout = on_timeout
  }
  return table.insert(WaiterQueue, struct)
end
