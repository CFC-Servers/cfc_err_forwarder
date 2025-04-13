ErrorForwarder = ErrorForwarder or {}

if SERVER then
    AddCSLuaFile( "cfc_err_forwarder/branch.lua" )
    AddCSLuaFile( "cfc_err_forwarder/client/forwarder.lua" )
end

if CLIENT then
    include( "cfc_err_forwarder/branch.lua" )
    include( "cfc_err_forwarder/client/forwarder.lua" )
end
