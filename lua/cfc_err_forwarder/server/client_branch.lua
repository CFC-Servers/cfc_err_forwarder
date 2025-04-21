function ErrorForwarder.Forwarder.GetBranch( ply )
    return ply.ErrorForwarder_Branch or "unknown branch"
end

hook.Add( "PlayerInitialSpawn", "CFC_ErrorForwarder_BranchSet", function( ply )
    local branch = ply:GetInfo( "cfc_err_forwarder_branch" )
    ply.ErrorForwarder_Branch = branch
end )
