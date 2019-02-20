require "luaerror"

local CFCErrorForwarder = {}

CFCErrorForwarder.errorQueue = {}

local fowardingAddress = "http://localhost:5000/webhooks/gmod/forward-errors"

function CFCErrorForwarder.receiveLuaError( err, realm, addonName, addonID )
    print("[CFC Error Forwarder] Received lua error!")
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

local function onSuccess( result )
    print("[CFC Error Forwarder] Successfully forwarded error(s)!")
end

local function onFailure( failure )
    print("[CFC Error Forwarder] Failed to forward error!")
    print( failure )
    print( failure )
    print( failure )
end

function CFCErrorForwarder.forwardError( obj )
    print("[CFC Error Forwarder] Forwaring lua error(s)!")
    http.Post( forwardingAddress, obj, onSuccess, onFailure )
end

local function combineErrors( queuedErrors )
    local struct = {}
    struct.errors = queuedErrors

    return struct
end

function CFCErrorForwarder.groomQueue()
    local errQueue = CFCErrorForwarder.errorQueue

    if #errQueue == 0 then return end

    local combinedErrors = combineErrors( errQueue )

    CFCErrorForwarder.forwardError( combinedErrors )

    CFCErrorForwarder.errorQueue = {}
end

timer.Create("CFC_ErrorForwarderQueue", 5, 0, CFCErrorForwarder.groomQueue )

hook.Remove( "LuaError", "CFC_ErrorForwarder" )
--hook.Add( "LuaError", "CFC_ErrorForwarder", CFCErrorForwarder.receiveLuaError )
hook.Add( "LuaError", "CFC_ErrorForwarder", function() print("AAAAAAAAAAAHHHHHHHHHHHHHHHH AHHHHHHHHHHHH FUCK") end)
