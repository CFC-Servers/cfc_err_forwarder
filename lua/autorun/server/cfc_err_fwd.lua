include( "cfc_err_forwarder/logger.lua" )

--- @class ErrorForwarder
local EF = ErrorForwarder
local log = EF.Logger
local colors = EF.colors

if util.IsBinaryModuleInstalled( "luaerror" ) then
    require( "luaerror" )
    luaerror.EnableCompiletimeDetour( true )
    luaerror.EnableClientDetour( true )
    luaerror.EnableRuntimeDetour( true )
else
    log.err( "LuaError module is not installed!" )
    log.warn( "This addon cannot function without the LuaError module, as it is the only way to get Lua error information." )
    log.warn( "Please visit this page and download the latest version of the module for your system ", colors.debug, "(then place it in lua/bin/):" )
    log.info( colors.highlight, "https://github.com/danielga/gm_luaerror/releases" )

    error( "ErrorForwarder: Cannot Load! LuaError module is not installed! (More info in logs)" )
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

include( "cfc_err_forwarder/init.lua" )
