require("luaerror")
luaerror.EnableCompiletimeDetour(true)
luaerror.EnableRuntimeDetour(true)

local errorQueue = {}

local forwardingAddress = "http://localhost:5000/webhooks/gmod/forward-errors"

local groomingIntervalInSeconds = 5

local addon = "CFC Error Forwarder"
local function log(msg)
    print("[" .. addon .. "] " .. msg)
end

local function incrementExistingError( errObj )
    local count = errObj.count

    errObj.count = count + 1
    errObj.occuredAt = os.time()
end

local function insertNewError( isRunTime, fullError, sourceFile, sourceLine, errorStr, stack )
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

    log( "Inserting lua error into queue.." )

    errorQueue[errorStr] = newError
    
    PrintTable( errorQueue )
end

local function receiveLuaError( isRunTime, fullError, sourceFile, sourceLine, errorStr, stack )
    log( "Received lua error!" )
 
    if errorQueue[errorStr] then 
        return incrementExistingError( errorQueue[errorStr] ) 
    end

    return insertNewError( isRunTime, fullError, sourceFile, sourceLine, errorStr, stack )
end

local function onSuccess( result )
    log( "Successfully forwarded error(s)! -- screeeeeeeeeeeeeeee" )
end

local function onFailure( failure )
    log( "Failed to forward error!" )
    print( failure )
end

local function forwardError( obj )
    log( "Forwarding lua error(s)!" )
    local data = {
        json = util.TableToJSON( obj )
    }

    http.Post( forwardingAddress, data, onSuccess, onFailure )
end

local function errorQueueIsEmpty()
    local errCount = table.Count( errorQueue )

    if errCount == 0 then return true end

    return false
end

local function forwardAllErrors()
    for _, data in pairs( errorQueue ) do
        forwardError( data )
    end

    errorQueue = {}
end

local function groomQueue()
    if errorQueueIsEmpty() then return end

    log( "Error Queue Contains " .. tostring( errCount ) .. " Errors!" )

    forwardAllErrors()
end

timer.Create("CFC_ErrorForwarderQueue", groomingIntervalInSeconds, 0, groomQueue )

hook.Remove( "LuaError", "CFC_ErrorForwarder" )
hook.Add( "LuaError", "CFC_ErrorForwarder", receiveLuaError )
