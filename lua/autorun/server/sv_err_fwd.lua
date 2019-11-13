
--
-- CFC Error Forwarder
-- Forwards Lua Errors to a webserver made to deal with them
--
require( "luaerror" )
luaerror.EnableCompiletimeDetour( true )
luaerror.EnableRuntimeDetour( true )

--
-- Constants
--
-- Intervals in seconds
local GROOMING_INTERVAL = 60

-- Address to forward errors to
local FORWARDING_ADDRESS = "http://local:5000/webhooks/gmod/forward-errors"

-- The beginning of every log message
local LOG_PREFIX = "[CFC Error Forwarder] "

-- The meat & potatoes
local CFCErrorForwarder = {}

--
-- Helper Methods
--
local function log( msg )
    print( LOG_PREFIX .. msg )
end

local function onSuccess( result )
    log( "Successfully forwarded error!" )
    CFCErrorForwarder.SuccessCount = CFCErrorForwarder.SucessCount + 1
end

local function onFailure( failure )
    log( "Failed to forward error!" )
    CFCErrorForwarder.FailureCount = CFCErrorForwarder.FailureCount + 1
end

local function getJsonTable( obj )
    return { ["json"] = util.TableToJSON( obj ) }
end

--
-- CFCErrorForwarder Operations
--
function CFCErrorForwarder.reset()
    CFCErrorForwarder.SuccessCount = 0
    CFCErrorForwarder.FailureCount = 0
    CFCErrorForwarder.ErrorQueue = {}
end

function CFCErrorForwarder.init()
    CFCErrorForwarder.reset()
end

function CFCErrorForwarder.addSuccess()
    log( "Successfully forwarded error!" )
    CFCErrorForwarder.SuccessCount = CFCErrorForwarder.SucessCount + 1
end

function CFCErrorForwarder.addFailure( failure )
    log( "Failed to forward error! (" .. tostring( failure ) .. ")" )
    CFCErrorForwarder.FailureCount = CFCErrorForwarder.FailureCount + 1
end

function CFCErrorForwarder.incrementExistingError( errorObject )
    errorObject.count = errorObject.count + 1
    errorObject["occuredAt"] = os.time()
end

function CFCErrorForwarder.errorExistsInQueue( errorString )
    return CFCErrorForwarder.ErrorQueue[errorString] ~= nil
end

function CFCErrorForwarder.insertNewError( isRunTime, fullError, sourceFile, sourceLine, errorString, stack )
    local newError = {}
    newError["isRunTime"]   = isRunTime
    newError["fullError"]   = fullError
    newError["sourceFile"]  = sourceFile
    newError["sourceLine"]  = sourceLine
    newError["errorString"] = errorString
    newError["stack"]       = stack
    newError["occuredAt"]   = os.time()
    newError["count"]       = 1

    log( "Inserting lua error into queue..." )

    CFCErrorForwarder.ErrorQueue[errorString] = newError
end

function CFCErrorForwarder.receiveLuaError( isRunTime, fullError, sourceFile, sourceLine, errorString, stack )
    log( "Received lua error!" )

    if CFCErrorForwarder.errorExistsInQueue( errorString ) then
        return CFCErrorForwarder.incrementExistingError( CFCErrorForwarder.ErrorQueue[errorString] )
    end

    CFCErrorForwarder.insertNewError( isRunTime, fullError, sourceFile, sourceLine, errorString, stack )
end

function CFCErrorForwarder.forwardError( obj )
    http.Post( FORWARDING_ADDRESS, getJsonTable( obj ), CFCErrorForwarder.addSuccess, CFCErrorForwarder.addFailure )
end

function CFCErrorForwarder.getNumberOfErrors()
    return table.Count( CFCErrorForwarder.ErrorQueue )
end

function CFCErrorForwarder.errorQueueIsEmpty()
    return CFCErrorForwarder.getNumberOfErrors() == 0
end

function CFCErrorForwarder.forwardAllErrors()
    if CFCErrorForwarder.errorQueueIsEmpty() then return end

    for _, errorData in pairs( CFCErrorForwarder.ErrorQueue ) do
        CFCErrorForwarder.forwardError( errorData )
    end

    logMessageFormat = "Successfully forwarded %d Errors, and failed to send %d!"
    log( string.format( logMessageFormat, CFCErrorForwarder.SuccessCount, CFCErrorForwarder.FailureCount ) )

    CFCErrorForwarder.reset()
end

function CFCErrorForwarder.groomQueue()
    log( "Grooming Error Queue... ( # of Errors: " .. tostring( CFCErrorForwarder.getNumberOfErrors() ) .. " )" )
    CFCErrorForwarder.forwardAllErrors()
end

--
-- Hooks
--
-- Run receiveLuaError operation on every LuaError event
hook.Remove( "LuaError", "CFC_ErrorForwarder" )
hook.Add( "LuaError", "CFC_ErrorForwarder", CFCErrorForwarder.receiveLuaError )

--
-- Startup
--
-- Initialize CFCErrorForwarder table
CFCErrorForwarder.init()

-- Infinite Grooming Timer repeating at GROOMING_INTERVAL seconds
timer.Create( "CFC_ErrorForwarderQueue", GROOMING_INTERVAL, 0, CFCErrorForwarder.groomQueue )
