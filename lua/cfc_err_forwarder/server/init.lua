include( "logger.lua" )
local log = ErrorForwarder.Logger
local colors = ErrorForwarder.colors

if util.IsBinaryModuleInstalled( "reqwest" ) then
    require( "reqwest" )
else
    log.err( "Reqwest module is not installed!" )
    log.warn( "This addon cannot function without the Reqwest module, as Discord blocks Gmod's base HTTP Agent." )
    log.warn( "Please visit this page and download the latest version of the module for your system ", colors.debug, "(then place it in lua/bin/):" )
    log.info( colors.highlight, "https://github.com/WilliamVenner/gmsv_reqwest/releases" )
    log.err( "Preventing addon from loading....." )

    return
end

require( "formdata" )
include( "helpers.lua" )
include( "config.lua" )
include( "discord_interface.lua" )
include( "error_forwarder.lua" )
include( "error_intake.lua" )
include( "client_info.lua" )
include( "external_addons.lua" )

log.info( "Loaded!" )
