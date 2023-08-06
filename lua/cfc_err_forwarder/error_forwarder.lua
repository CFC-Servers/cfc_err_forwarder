local os_Time = os.time
local rawget = rawget
local rawset = rawset

local queueName = "CFC_ErrorForwarderQueue"
local Config = ErrorForwarder.Config
local Helpers = ErrorForwarder.Helpers
local log = ErrorForwarder.Logger
local Discord = ErrorForwarder.Discord

local context = include( "context.lua" )

--- @class ErrorForwarderForwarder
ErrorForwarder.Forwarder = {}
local Forwarder = ErrorForwarder.Forwarder
Forwarder.queue = {}

--- Queue an error into the forwarder queue
--- @param luaError ErrorForwarder_LuaError
--- @param isClientside boolean
--- @param ply Player?
function Forwarder:QueueError( luaError, isClientside, ply )
    local fullError = luaError.fullError
    if self:errorIsQueued( fullError ) then
        self:incrementError( fullError )
        return
    end

    local localsContext, upvaluesContext = context( luaError.stack )
    Helpers.SaveLocals( luaError.stack )
    Helpers.StripStack( luaError.stack )

    local plyName, plySteamID
    if ply then
        plyName = ply:Nick()
        plySteamID = ply:SteamID()
    end

    --- @class ErrorForwarder_QueuedError
    local newError = {
        count = 1,
        luaError = luaError,
        isClientside = isClientside,
        plyName = plyName,
        plySteamID = plySteamID,
        reportInterval = Config.groomInterval:GetInt() or 60,
        fullContext = {
            locals = localsContext,
            upvalues = upvaluesContext,
        }
    }

    if isClientside then
        newError = addPlyToObject( newError, ply )
    end

    log.debug( "Inserting error into queue: " .. luaError.fullError )
    rawset( self.queue, fullError, newError )
end

--- Forwards all queued Errors to Discord
function Forwarder:ForwardErrors()
    for errorString, errorData in pairs( self.queue ) do
        log.debug( "Sending queued error to Discord: " .. errorString )
        ProtectedCall( function()
            Discord:Send( errorData )
        end )
    end

    table.Empty( self.queue )
end

function Forwarder:groomQueue()
    local count = table.Count( self.queue )
    if count == 0 then return end

    log.debug( "Grooming Error Queue of size: " .. count )
    self:ForwardErrors()
end

function Forwarder:errorIsQueued( fullError )
    return rawget( self.queue, fullError ) ~= nil
end

function Forwarder:startTimer()
    timer.Create( queueName, Config.groomInterval:GetInt() or 60, 0, function()
        ProtectedCall( function()
            self:groomQueue()
        end )
    end )
end

function Forwarder:adjustTimer( interval )
    timer.Adjust( queueName, tonumber( interval ) )
end

function Forwarder:incrementError( fullError )
    local item = rawget( self.queue, fullError )
    item.count = item.count + 1
    item.occurredAt = os_Time()
end

Forwarder:startTimer()
