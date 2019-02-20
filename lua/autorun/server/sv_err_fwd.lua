require("luaerror")
luaerror.EnableCompiletimeDetour(true)
luaerror.EnableRuntimeDetour(true)

local CFCErrorForwarder = {}

CFCErrorForwarder.errorQueue = {}
local errorQueue = CFCErrorForwarder.errorQueue

local forwardingAddress = "http://localhost:5000/webhooks/gmod/forward-errors"

local groomingIntervalInSeconds = 5

function CFCErrorForwarder.incrementExistingError( errObj )
    local count = errObj.count

    errObj.count = count + 1
    errObj.occuredAt = os.time()
end

function CFCErrorForwarder.insertNewError( isRunTime, fullError, sourceFile, sourceLine, errorStr, stack )
    local newError = {
        isRunTime  = isRunTime,
        fullError  = fullError,
        sourceFile = sourceFile,
        sourceLine = sourceLine,
        errorStr   = errorStr,
        stack      = stack,
        occuredAt  = os.time(),
        count      = 1
    }

    print( "[CFC Error Forwarder] Inserting lua error into queue.." )

    errorQueue[errorStr] = newError
    
    PrintTable(errorQueue)
end

function CFCErrorForwarder.receiveLuaError( isRunTime, fullError, sourceFile, sourceLine, errorStr, stack )
    print( "[CFC Error Forwarder] Received lua error!" )
 
    if errorQueue[errorStr] then 
        return CFCErrorForwarder.incrementExistingError( errorQueue[errorStr] ) 
    end

    return CFCErrorForwarder.insertNewError( isRunTime, fullError, sourceFile, sourceLine, errorStr, stack )

end

local function onSuccess( result )
    print( "[CFC Error Forwarder] Successfully forwarded error(s)! -- screeeeeeeeeeeeeeee" )
end

local function onFailure( failure )
    print( "[CFC Error Forwarder] Failed to forward error!" )
    print( failure )
end

function CFCErrorForwarder.forwardError( obj )
    print("[CFC Error Forwarder] Forwaring lua error(s)!")
    local data = {
        json = util.TableToJSON( obj )
    }

    http.Post( forwardingAddress, data, onSuccess, onFailure )
end

function CFCErrorForwarder.forwardAllErrors()
    for _, data in pairs( errorQueue ) do
        CFCErrorForwarder.forwardError( data )
    end

    errorQueue = {}
end

function CFCErrorForwarder.groomQueue()
    local errCount = table.Count( errorQueue )

    if errCount == 0 then return end

    print( "[CFC Error Forwarder] Error Queue Contains " .. tostring( errCount ) .. " Errors!" )

    CFCErrorForwarder.forwardAllErrors()
end

timer.Create("CFC_ErrorForwarderQueue", groomingIntervalInSeconds, 0, CFCErrorForwarder.groomQueue )

hook.Remove( "LuaError", "CFC_ErrorForwarder" )
hook.Add( "LuaError", "CFC_ErrorForwarder", CFCErrorForwarder.receiveLuaError )
