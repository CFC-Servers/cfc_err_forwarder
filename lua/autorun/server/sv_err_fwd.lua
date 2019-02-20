require("luaerror")
luaerror.EnableCompiletimeDetour(true)
luaerror.EnableRuntimeDetour(true)

local CFCErrorForwarder = {}

CFCErrorForwarder.errorQueue = {}

local forwardingAddress = "http://localhost:5000/webhooks/gmod/forward-errors"

function CFCErrorForwarder.receiveLuaError( isRunTime, fullError, sourceFile, sourceLine, errorStr, stack )
    print( "[CFC Error Forwarder] Received lua error!" )
    if CFCErrorForwarder.errorQueue[tostring(errorStr)] then
        --local count = errQueue[errorStr]["count"]
        --CFCErrorForwarder.errorQueue[errorStr]["count"] = count + 1
        --CFCErrorForwarder.errorQueue[errorStr]["occuredAt"] = tostring(os.time())

        return
    end

    local struct = {}

    struct["isRunTime"] = tostring(isRunTime)
    --struct["fullError"] = tostring(fullError)
    --struct["sourceFile"] = tostring(sourceFile)
    --struct["sourceLine"] = tostring(sourceLine)
    --struct["errorStr"] = tostring(errorstr)
    --struct["stack"] = tostring(stack)
    --struct["occuredAt"] = tostring(os.time())
    --struct["count"] = 1

    print( "[CFC Error Forwarder] Inserting lua error into queue.." )


    CFCErrorForwarder.errorQueue["test"] = struct
end

local function onSuccess( result )
    print( "[CFC Error Forwarder] Successfully forwarded error(s)! -- screeeeeeeeeeeeeeee" )
end

local function onFailure( failure )
    print( "[CFC Error Forwarder] Failed to forward error!" )
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
    --print( "[CFC Error Forwarder] Grooming error queue!" )

    local errQueue = CFCErrorForwarder.errorQueue
    local errCount = table.Count( errQueue )

    --print( "[CFC Error Forwarder] Error Queue length: " .. tostring( errCount ))
    if errCount == 0 then return end

    print( "[CFC Error Forwarder] Error Queue is not empty (#" .. tostring( errCount ) .. "). Combining errors.." )

    local combinedErrors = combineErrors( errQueue )

    print( "[CFC Error Forwarder] Errors combined. Forwarding.." )

    CFCErrorForwarder.forwardError( combinedErrors )

    CFCErrorForwarder.errorQueue = {}
end

timer.Create("CFC_ErrorForwarderQueue", 5, 0, CFCErrorForwarder.groomQueue )

hook.Remove( "LuaError", "CFC_ErrorForwarder" )
hook.Add( "LuaError", "CFC_ErrorForwarder", CFCErrorForwarder.receiveLuaError )
