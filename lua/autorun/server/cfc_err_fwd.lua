require("reqwest")
local useErrorModule = false
if util.IsBinaryModuleInstalled("luaerror") then
  require("luaerror")
  luaerror.EnableCompiletimeDetour(true)
  luaerror.EnableClientDetour(true)
  luaerror.EnableRuntimeDetour(true)
  useErrorModule = true
end
SetGlobal2Bool("CFC_ErrorForwarder_ManualSend", not useErrorModule)
util.AddNetworkString("cfc_err_forwarder_clbranch")
util.AddNetworkString("cfc_err_forwarder_clerror")
local timerName = "CFC_ErrorForwarderQueue"
local errorForwarder = include("cfc_err_forwarder/error_forwarder.lua")
local discordBuilder = include("cfc_err_forwarder/discord_interface.lua")
local convarPrefix = "cfc_err_forwarder"
local convarFlags = FCVAR_ARCHIVE + FCVAR_PROTECTED
local makeConfig
makeConfig = function(name, value, help)
  return CreateConVar(tostring(convarPrefix) .. "_" .. tostring(name), value, convarFlags, help)
end
local Config = {
  groomInterval = makeConfig("interval", "60", "Interval at which errors are parsed and sent to Discord"),
  clientEnabled = makeConfig("client_enabled", "1", "Whether or not to track and forward Clientside errors"),
  bucketSize = makeConfig("bucket_size", "5", "Client -> Server rate limiting bucket size. (Only applies to clientside errors when not using the luaerror dll)"),
  webhook = {
    client = makeConfig("client_webhook", "", "Discord Webhook URL"),
    server = makeConfig("server_webhook", "", "Discord Webhook URL")
  }
}
local log
log = function(self, ...)
  return print("[ErrorForwarder]", ...)
end
local logger = {
  trace = function() end,
  debug = function() end,
  info = log,
  warn = log,
  error = log
}
local Discord = discordBuilder(Config)
local ErrorForwarder = errorForwarder(logger, Discord, Config)
timer.Create(timerName, Config.groomInterval:GetInt() or 60, 0, function()
  local success, err = pcall((function()
    local _base_0 = ErrorForwarder
    local _fn_0 = _base_0.groomQueue
    return function(...)
      return _fn_0(_base_0, ...)
    end
  end)())
  if not success then
    return logger:error("Groom Queue failed!", err)
  end
end)
cvars.AddChangeCallback("cfc_err_forwarder_interval", function(_, _, value)
  return timer.Adjust(timerName, tonumber(value), "UpdateTimer")
end)
if useErrorModule then
  hook.Add("LuaError", "CFC_ServerErrorForwarder", (function()
    local _base_0 = ErrorForwarder
    local _fn_0 = _base_0.receiveSVError
    return function(...)
      return _fn_0(_base_0, ...)
    end
  end)())
  hook.Add("ClientLuaError", "CFC_ClientErrorForwarder", (function()
    local _base_0 = ErrorForwarder
    local _fn_0 = _base_0.receiveCLError
    return function(...)
      return _fn_0(_base_0, ...)
    end
  end)())
else
  include("cfc_err_forwarder/plain_receiver.lua")(logger, ErrorForwarder, Config)
end
hook.Add("ShutDown", "CFC_ShutdownErrorForwarder", (function()
  local _base_0 = ErrorForwarder
  local _fn_0 = _base_0.forwardErrors
  return function(...)
    return _fn_0(_base_0, ...)
  end
end)())
net.Receive("cfc_err_forwarder_clbranch", function(_, ply)
  if not ply.CFC_ErrorForwarder_CLBranch then
    ply.CFC_ErrorForwarder_CLBranch = net.ReadString()
  end
end)
return logger:info("Loaded!")
