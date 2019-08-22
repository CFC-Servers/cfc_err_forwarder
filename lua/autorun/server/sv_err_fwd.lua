require("luaerror")
luaerror.EnableCompiletimeDetour(true)
luaerror.EnableRuntimeDetour(true)

-- In seconds
ERROR_REPORT_INTERVAL = 60

local CFCErrorForwarder = {}

CFCErrorForwarder.errorQueue = {}

local forwardingAddress = "http://localhost:5000/webhooks/gmod/forward-errors"

function CFCErrorForwarder.receiveLuaError( isRunTime, fullError, sourceFile, sourceLine, errorStr, stack )
    print( "[CFC Error Forwarder] Received lua error!" )
    if CFCErrorForwarder.errorQueue[errorStr] then
        local count = CFCErrorForwarder.errorQueue[errorStr]["count"]

        CFCErrorForwarder.errorQueue[errorStr]["count"] = count + 1
        CFCErrorForwarder.errorQueue[errorStr]["occuredAt"] = os.time()

        return
    end

    local struct = {}

    struct["isRunTime"] = isRunTime
    struct["reportInterval"] = ERROR_REPORT_INTERVAL
    struct["fullError"] = fullError
    struct["sourceFile"] = sourceFile
    struct["sourceLine"] = sourceLine
    struct["errorStr"] = errorStr
    struct["stack"] = stack
    struct["occuredAt"] = os.time()
    struct["count"] = 1

    print( "[CFC Error Forwarder] Inserting lua error into queue.." )

    CFCErrorForwarder.errorQueue[errorStr] = struct
end

local function onSuccess( result )
    print( "[CFC Error Forwarder] Successfully forwarded error(s)!" )
end

local function onFailure( failure )
    print( "[CFC Error Forwarder] Failed to forward error!" )
    print( failure )
    print( failure )
    print( failure )
end

function CFCErrorForwarder.forwardError( obj )
    print("[CFC Error Forwarder] Forwaring lua error(s)!")
    local json = util.TableToJSON( obj )
    local data = {}
    data.json = json

    http.Post( forwardingAddress, data, onSuccess, onFailure )
end

function CFCErrorForwarder.groomQueue()
    --print( "[CFC Error Forwarder] Grooming error queue!" )

    local errQueue = CFCErrorForwarder.errorQueue
    local errCount = table.Count( errQueue )

    --print( "[CFC Error Forwarder] Error Queue length: " .. tostring( errCount ))
    if errCount == 0 then return end

    print( "[CFC Error Forwarder] Error Queue is not empty (#" .. tostring( errCount ) .. ")" )

    for err, data in pairs(errQueue) do
        CFCErrorForwarder.forwardError( data )
    end

    CFCErrorForwarder.errorQueue = {}
end

timer.Create("CFC_ErrorForwarderQueue", ERROR_REPORT_INTERVAL, 0, CFCErrorForwarder.groomQueue )

hook.Remove( "LuaError", "CFC_ErrorForwarder" )
hook.Add( "LuaError", "CFC_ErrorForwarder", CFCErrorForwarder.receiveLuaError )
