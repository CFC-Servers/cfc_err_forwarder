require( "formdata" )
include( "logger.lua" )
include( "helpers.lua" )
include( "config.lua" )
include( "discord_interface.lua" )
include( "error_forwarder.lua" )
include( "error_intake.lua" )
include( "client_branch.lua" )

local log = ErrorForwarder.Logger
local colors = ErrorForwarder.colors

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

hook.Add( "ShutDown", "CFC_ShutdownErrorForwarder", function()
    log.warn( "Shut Down detected, saving unsent queue items..." )
    ErrorForwarder.Forwarder:ForwardErrors()

    if not ErrorForwarder.Config.backup:GetBool() then return end
    ErrorForwarder.Discord:saveQueue()
end )

log.info( "Loaded!" )
