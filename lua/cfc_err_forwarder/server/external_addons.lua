
-- Makes the physgun_host https://physgun.com/  net detour properly log errors as their original uses xpcall + print which is not caught and effectively useless.
if PhysgunPostCallNetIncomming and debug.getinfo( PhysgunPostCallNetIncomming ).short_src == [=[[string "__phys_aa_caller.lua"]]=] then -- Only detour if the original function is from the physgun addon.
    local ent = Entity
    function PhysgunPostCallNetIncomming( len, entIndex )
        ProtectedCall( function()
            net.Incoming( len, ent( entIndex ) )
        end )
    end
end
