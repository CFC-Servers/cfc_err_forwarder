require("luaerror")
luaerror.EnableCompiletimeDetour(true)
luaerror.EnableRuntimeDetour(true)

local CFCErrorForwarder = {}
CFCErrorForwarder.errorQueue = {}

local forwardingAddress = "http://localhost:5000/webhooks/gmod/forward-errors"

local groomingIntervalInSeconds = 5

local addon = "CFC Error Forwarder"
local function log(msg)
    print("[" .. addon .. "] " .. msg)
end

function CFCErrorForwarder.incrementExistingError( errObj )
    local count = errObj.count

    errObj.count = count + 1
    errObj.occuredAt = os.time()
end

function CFCErrorForwarder.insertNewError( isRunTime, fullError, sourceFile, sourceLine, errorStr, stack )
    local newError = {}
    newError.isRunTime  = isRunTime
    newError.fullError  = fullError
    newError.sourceFile = sourceFile
    newError.sourceLine = sourceLine
    newError.errorStr   = errorStr
    newError.stack      = stack
    newError.occuredAt  = os.time()
    newError.count      = 1

    log( "Inserting lua error into queue.." )

    CFCErrorForwarder.errorQueue[errorStr] = newError
    
    PrintTable( CFCErrorForwarder.errorQueue )
end

function CFCErrorForwarder.receiveLuaError( isRunTime, fullError, sourceFile, sourceLine, errorStr, stack )
    log( "Received lua error!" )
 
    local errorQueue = CFCErrorForwarder.errorQueue

    if errorQueue[errorStr] then 
        CFCErrorForwarder.incrementExistingError( errorQueue[errorStr] )
        return
    end

    CFCErrorForwarder.insertNewError( isRunTime, fullError, sourceFile, sourceLine, errorStr, stack )
end

local function onSuccess( result )
    log( "Successfully forwarded error(s)! -- screeeeeeeeeeeeeeee" )
end

local function onFailure( failure )
    log( "Failed to forward error!" )
    print( failure )
end

function CFCErrorForwarder.forwardError( obj )
    log( "Forwarding lua error(s)!" )

    local data = {}
    local json = util.TableToJSON( obj )

    data.json  = json

    http.Post( forwardingAddress, data, onSuccess, onFailure )
end

function CFCErrorForwarder.errorQueueIsEmpty()
    local errCount = table.Count( CFCErrorForwarder.errorQueue )

    return errCount == 0
end

function CFCErrorForwarder.forwardAllErrors()
    for _, data in pairs( CFCErrorForwarder.errorQueue ) do
        CFCErrorForwarder.forwardError( data )
    end

    CFCErrorForwarder.errorQueue = {}
end

function CFCErrorForwarder.groomQueue()
    if CFCErrorForwarder.errorQueueIsEmpty() then return end

    log( "Error Queue Contains " .. tostring( errCount ) .. " Errors!" )

    CFCErrorForwarder.forwardAllErrors()
end

timer.Create("CFC_ErrorForwarderQueue", groomingIntervalInSeconds, 0, CFCErrorForwarder.groomQueue )

hook.Remove( "LuaError", "CFC_ErrorForwarder" )
hook.Add( "LuaError", "CFC_ErrorForwarder", CFCErrorForwarder.receiveLuaError )
