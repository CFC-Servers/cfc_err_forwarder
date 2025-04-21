ErrorForwarder = ErrorForwarder or {}

if SERVER then
    AddCSLuaFile( "cfc_err_forwarder/client/branch.lua" )
    AddCSLuaFile( "cfc_err_forwarder/client/forwarder.lua" )

    include( "cfc_err_forwarder/server/init.lua" )
end

if CLIENT then
    include( "cfc_err_forwarder/client/branch.lua" )
    include( "cfc_err_forwarder/client/forwarder.lua" )
end
