if SERVER then
    AddCSLuaFile()
    util.AddNetworkString( "cfc_err_forwarder_clbranch" )

    local branches = {}

    local function setBranch( ply, branch )
        branches[ply] = branch
    end

    local function getBranch( ply )
        return branches[ply]
    end

    ErrorForwarder.CLBranches = branches
    ErrorForwarder.Forwarder.GetBranch = getBranch

    net.Receive( "cfc_err_forwarder_clbranch", function( _, ply )
        if getBranch( ply ) then return end

        local branch = net.ReadString()
        setBranch( ply, branch )
    end )

    hook.Add( "PlayerDisconnected", "CFC_ErrorForwarder_BranchCleanup", function( ply )
        setBranch( ply, nil )
    end )
end

if CLIENT then
    hook.Add( "InitPostEntity", "CFC_ErrorForwarder_BranchSetter", function()
        net.Start( "cfc_err_forwarder_clbranch" )
        net.WriteString( BRANCH )
        net.SendToServer()
    end )
end
