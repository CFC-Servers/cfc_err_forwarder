ErrorForwarder.ClientInfo = ErrorForwarder.ClientInfo or {}

function ErrorForwarder.ClientInfo.GetBranch( ply )
    return ply.ErrorForwarder_Branch or "unknown branch"
end

function ErrorForwarder.ClientInfo.GetOS( ply )
    return ply.ErrorForwarder_OS or "unknown"
end

function ErrorForwarder.ClientInfo.GetCountry( ply )
    return ply.ErrorForwarder_Country or "unknown"
end

function ErrorForwarder.ClientInfo.GetGModVersion( ply )
    return ply.ErrorForwarder_GModVersion or "unknown"
end

hook.Add( "PlayerInitialSpawn", "CFC_ErrorForwarder_BranchSet", function( ply )
    ply.ErrorForwarder_Branch = ply:GetInfo( "cfc_err_forwarder_branch" )
    ply.ErrorForwarder_OS = ply:GetInfo( "cfc_err_forwarder_os" )
    ply.ErrorForwarder_Country = ply:GetInfo( "cfc_err_forwarder_country" )
    ply.ErrorForwarder_GModVersion = ply:GetInfo( "cfc_err_forwarder_gmodversion" )
end )
