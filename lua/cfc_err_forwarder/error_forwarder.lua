local os_Time = os.time

local log = ErrorForwarder.Logger
local Config = ErrorForwarder.Config
local Helpers = ErrorForwarder.Helpers
local Discord = ErrorForwarder.Discord
local queueName = "CFC_ErrorForwarderQueue"

local context = include( "context.lua" )

--- @class ErrorForwarderForwarder
ErrorForwarder.Forwarder = {}
--- @class ErrorForwarderForwarder
local Forwarder = ErrorForwarder.Forwarder
Forwarder.queue = {}

--- Queue an error into the forwarder queue
--- @param luaError ErrorForwarder_LuaError
function Forwarder:QueueError( luaError )
    local fullError = luaError.fullError
    if self:errorIsQueued( fullError ) then
        self:incrementError( fullError )
        return
    end

    local locals, upvalues = context( luaError.stack )
    Helpers.StripStack( luaError.stack )

    local ply = luaError.ply
    local isClientside = false

    local plyName, plySteamID, branch
    if ply then
        plyName = ply:Nick()
        plySteamID = ply:SteamID()
        branch = Forwarder.GetBranch( ply ) or "Not sure yet"
        isClientside = true
    else
        branch = BRANCH
    end

    --- @class ErrorForwarder_QueuedError
    local newError = {
        count = 1,
        luaError = luaError,
        isClientside = isClientside,
        plyName = plyName,
        plySteamID = plySteamID,
        branch = branch,
        reportInterval = Config.groomInterval:GetInt() or 60,
        fullContext = {
            locals = locals,
            upvalues = upvalues,
        }
    }

    log.debug( "Inserting error into queue: " .. luaError.fullError )
    self.queue[fullError] = newError
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
    return self.queue[fullError]
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
    local item = self.queue[fullError]
    item.count = item.count + 1
    item.occurredAt = os_Time()
end

Forwarder:startTimer()
