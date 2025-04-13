if SERVER then
    AddCSLuaFile()

    function ErrorForwarder.Forwarder.GetBranch( ply )
        return ply.ErrorForwarder_Branch or "unknown branch"
    end

    hook.Add( "PlayerInitialSpawn", "CFC_ErrorForwarder_BranchSet", function( ply )
        local branch = ply:GetInfo( "cfc_err_forwarder_branch" )
        ply.ErrorForwarder_Branch = branch
    end )
end

if CLIENT then
    CreateConVar( "cfc_err_forwarder_branch", BRANCH, { FCVAR_CHEAT, FCVAR_PROTECTED, FCVAR_USERINFO } )
end
