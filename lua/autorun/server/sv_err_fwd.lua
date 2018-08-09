local CFCErrorForwarder = {}

CFCErrorForwarder.errorQueue = {}

function CFCErrorForwarder.receiveLuaError( err, realm, addonName, addonID )
    local errQueue = CFCErrorForwarder.errorQueue

    if errQueue[err] then
        local count = errQueue[err]["count"]
        errQueue[err]["count"] = count + 1
        errQueue[err]["occuredAt"] = os.time()

        return
    end

    local struct = {}

    struct["error"] = err
    struct["realm"] = realm
    struct["addonName"] = addonName
    struct["addonID"] = addonID
    struct["occuredAt"] = os.time()
    struct["count"] = 1

    errQueue[err] = struct
end

function CFCErrorForwarder.fowardError( obj )
    http.Post( "https://scripting.cfcservers.org/cfc2/forward_error", obj, function( result )
        return print("Succesfully forwarded error!")
    end, function( failure )
        -- Ironic.
        --  - The Senate
        print("Failed to forward error!")
        return print( failure )
    end)
end

function CFCErrorForwarder.groomQueue()
    local errQueue = CFCErrorForwarder.errorQueue

    if #errQueue == 0 then return end

    errQueue( table.remove( errQueue, 1 ) )
end

timer.Create("CFC_ErrorForwarderQueue", 5, 0, CFCErrorForwarder.groomQueue )

hook.Remove( "OnLuaError", "CFC_ErrorForwarder" )
hook.Add( "OnLuaError", "CFC_ErrorForwarder", CFCErrorForwarder.receiveLuaError )
