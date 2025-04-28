local CurTime = CurTime

local Formatter = include( "cfc_err_forwarder/server/formatter/formatter.lua" )
local Values = include( "cfc_err_forwarder/server/formatter/values_full.lua" )

local log = ErrorForwarder.Logger
local Config = ErrorForwarder.Config

local function getRetryAfter( body )
    body = util.JSONToTable( body )
    local retryAfter = body and body.retry_after

    return tonumber( retryAfter ) or 5
end

local DiscordInterface = {
    queue = {},
    running = false,
    retryAfter = nil,
    saveFile = "cfc_error_forwarder_queue.json",
    requestTemplate = {
        timeout = 25,
        method = "POST",
        headers = { ["User-Agent"] = "CFC Error Forwarder v1" }
    },
}
local DI = DiscordInterface

function DI:new()
    self.requestTemplate.success = function( code, body )
        self:onSuccess( code, body )
    end

    self.requestTemplate.failed = function( reason )
        self:onFailure( reason )
    end

    if Config.backup:GetBool() then
        hook.Add( "InitPostEntity", "CFC_ErrForwarder_LoadQueue", function()
            ProtectedCall( function()
                self:loadQueue()
            end )
        end )
    end
end

function DI:saveQueue()
    if #self.queue == 0 then
        if file.Exists( self.saveFile, "DATA" ) then
            file.Delete( self.saveFile, "DATA" )
        end

        return
    end

    log.info( "Saving " .. #self.queue .. " unsent errors to queue file. (They will be processed on next server start)" )
    file.Write( self.saveFile, util.TableToJSON( self.queue ) )
end

function DI:loadQueue()
    local saved = file.Read( self.saveFile, "DATA" )
    if not ( saved and #saved > 0 ) then return end

    local savedQueue = util.JSONToTable( saved )
    if not ( savedQueue and #savedQueue > 0 ) then return end

    log.info( "Loaded " .. #savedQueue .. " items from queue file." )

    for _, item in ipairs( savedQueue ) do
        self:enqueue( item )
    end

    file.Delete( self.saveFile, "DATA" )
end

function DI:getUrl( isClientside )
    local realm = isClientside and "client" or "server"
    local url = Config.webhook[realm]
    if url then url = url:GetString() end

    return url
end

function DI:sendNext()
    if self.waitUntil and CurTime() < self.waitUntil then return end

    local item = table.remove( self.queue, 1 )
    if not item then
        if Config.backup:GetBool() then
            self:saveQueue()
        end

        self.running = false
        return
    end

    log.info( "Sending Discord webhook. Queue size: " .. #self.queue )

    local success = ProtectedCall( function()
        local data = FormData()
        data:Append( "payload_json", item.body )

        if Config.includeFullContext:GetBool() then
            local context = item.rawData.fullContext
            local locals = context.locals
            if locals then
                local formattedValues = Values( locals, "locals" )

                if formattedValues and #formattedValues > 0 then
                    data:Append( "files[0]", formattedValues, "m", "full_locals.json" )
                end
            end

            local upvalues = context.upvalues
            if upvalues then
                local formattedValues = Values( upvalues, "upvalues" )

                if formattedValues and #formattedValues > 0 then
                    data:Append( "files[1]", formattedValues, "m", "full_upvalues.json" )
                end
            end
        end

        local newItem = table.Copy( self.requestTemplate )
        newItem.url = self:getUrl( item.isClientside )
        newItem.body = data:Read()
        newItem.headers = table.Merge(
            data:GetHeaders(),
            newItem.headers
        )

        reqwest( newItem )
    end )

    if not success then
        self:sendNext()
    end
end

function DI:enqueue( item )
    table.insert( self.queue, item )

    if not self.running then
        self.running = true
        self:sendNext()
    end
end

function DI:onRateLimit( body )
    self.retryAfter = getRetryAfter( body )
    log.warn( "Rate limited. Continuing in " .. self.retryAfter .. " seconds." )

    timer.Create( "CFC_ErrForwarder_DiscordRateLimit", self.retryAfter, 1, function()
        self.retryAfter = nil
        self:sendNext()
    end )

    if Config.backup:GetBool() then self:saveQueue() end
end

function DI:onSuccess( code, body )
    if code == 429 then
        self:onRateLimit( body )
    elseif code >= 400 then
        log.err( "Received failure code on webhook send: Code: " .. code .. " | Body:\n " .. body )
    end

    self:sendNext()
end

function DI:onFailure( reason )
    log.err( "Failed to send webhook: " .. reason )
    self:sendNext()
end

function DI:Send( data )
    local isClientside = data.isClientside
    local url = self:getUrl( isClientside )

    if not url or #url == 0 then
        log.err( "Missing Discord webhook URL for " .. ( isClientside and "client" or "server" ) .. " realm." )
        return
    end

    self:enqueue{
        isClientside = isClientside,
        body = Formatter( data ),
        rawData = data
    }
end

DI:new()
ErrorForwarder.Discord = DI
