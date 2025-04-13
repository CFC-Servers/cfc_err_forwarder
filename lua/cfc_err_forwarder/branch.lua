if SERVER then
    AddCSLuaFile()

    local branches = {}

    local function setBranch( ply, branch )
        branches[ply] = branch
    end

    local function getBranch( ply )
        return branches[ply]
    end

    ErrorForwarder.CLBranches = branches
    ErrorForwarder.Forwarder.GetBranch = getBranch

    hook.Add( "PlayerInitialSpawn", "CFC_ErrorForwarder_BranchSet", function( ply )
        local branch = ply:GetInfo( "cfc_err_forwarder_branch" )
        setBranch( ply, branch )
    end )

    hook.Add( "PlayerDisconnected", "CFC_ErrorForwarder_BranchCleanup", function( ply )
        setBranch( ply, nil )
    end )
end

if CLIENT then
    CreateConVar( "cfc_err_forwarder_branch", BRANCH, { FCVAR_CHEAT, FCVAR_PROTECTED, FCVAR_USERINFO } )
end
