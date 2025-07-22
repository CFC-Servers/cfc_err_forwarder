local os_Time = os.time

local log = ErrorForwarder.Logger
local Config = ErrorForwarder.Config
local Helpers = ErrorForwarder.Helpers
local Discord = ErrorForwarder.Discord
local queueName = "CFC_ErrorForwarderQueue"

local context
if Config.includeFullContext:GetBool() then
    context = include( "context.lua" )
end
cvars.AddChangeCallback( Config.includeFullContext:GetName(), function( _, _, newValue )
    if tobool( newValue ) and not context then
        context = include( "context.lua" )
    end
end )

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

    Helpers.StripStack( luaError.stack )

    local ply = luaError.ply
    local isClientside = false

    local plyName, plySteamID, branch, systemOS, country, gmodVersion, ping
    if ply then
        plyName = ply:Nick()
        plySteamID = ply:SteamID()
        branch = ErrorForwarder.ClientInfo.GetBranch( ply )
        systemOS = ErrorForwarder.ClientInfo.GetOS( ply )
        country = ErrorForwarder.ClientInfo.GetCountry( ply )
        ping = ply:Ping()
        gmodVersion = ErrorForwarder.ClientInfo.GetGModVersion( ply )
        isClientside = true
    else
        branch = BRANCH
        gmodVersion = VERSIONSTR
    end

    --- @class ErrorForwarder_QueuedError
    local newError = {
        count = 1,
        luaError = luaError,
        isClientside = isClientside,
        plyName = plyName,
        plySteamID = plySteamID,
        branch = branch,
        systemOS = systemOS,
        country = country,
        ping = ping,
        gmodVersion = gmodVersion,
        reportInterval = Config.groomInterval:GetInt() or 60
    }

    if Config.includeFullContext:GetBool() then
        local locals, upvalues = context( luaError.stack )
        newError.fullContext = {
            locals = locals,
            upvalues = upvalues,
        }
    end

    local shouldQueue = hook.Run( "CFC_ErrorForwarder_PreQueue", newError )
    if shouldQueue == false then return end

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

function Forwarder:getInterval()
    return Config.groomInterval:GetInt() or 60
end

function Forwarder:startTimer()
    local lastRun = os_Time()
    timer.Create( queueName, 0, 0, function() -- 0 tick timer so it still runs during hibernation
        ProtectedCall( function()
            if os_Time() - lastRun < self:getInterval() then return end
            lastRun = os_Time()

            self:groomQueue()
        end )
    end )
end

function Forwarder:incrementError( fullError )
    local item = self.queue[fullError]
    item.count = item.count + 1
    item.occurredAt = os_Time()
end

Forwarder:startTimer()

hook.Add( "ShutDown", "CFC_ShutdownErrorForwarder", function()
    log.warn( "Shut Down detected, saving unsent queue items..." )
    ErrorForwarder.Forwarder:ForwardErrors()

    if not ErrorForwarder.Config.backup:GetBool() then return end
    ErrorForwarder.Discord:saveQueue()
end )
