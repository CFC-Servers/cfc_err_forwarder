Formatter = include "formatter/formatter.lua"

getRetryAfter = (body, headers) ->
    body = util.JSONToTable body
    retryAfter = body and body.retry_after

    return tonumber(retryAfter) or 5

-- DiscordInterface tries to send its queue as fast as it can.
-- After one webook succeeds, it will proceed to send the next one until it runs out or gets rate limited.
-- Rate limiting is automatically handled.
class DiscordInterface
    new: (logger, config) =>
        @queue = {}
        @config = config
        @running = false
        @retryAfter = nil
        @logger = logger\scope "DiscordInterface"
        @saveFile = "cfc_error_forwarder_queue.json"
        @requestTemplate =
            timeout: 10
            method: "POST"
            success: @\onSuccess
            failed: @\onFailure
            type: "application/json"
            headers: "User-Agent": "CFC Error Forwarder v1"

        if @config.backup\GetBool!
            hook.Add "InitPostEntity", "CFC_ErrForwarder_LoadQueue", -> ProtectedCall @\loadQueue

    -- Saves the current queue to a file so it can be reloaded if the server restarts/changes levels/crashes etc.
    saveQueue: =>
        if #@queue == 0
            if file.Exists @saveFile, "DATA"
                file.Delete @saveFile

            return

        @logger\info "Saving #{#@queue} unsent errors to queue file. (They will be processed on next server start)"
        file.Write @saveFile, util.TableToJSON @queue

    loadQueue: =>
        saved = file.Read @saveFile, "DATA"
        return unless saved and #saved > 0

        savedQueue = util.JSONToTable saved
        return unless savedQueue and #savedQueue > 0

        @logger\info "Loaded #{#savedQueue} items from queue file."

        @enqueue item for item in *savedQueue
        file.Delete @saveFile

    getUrl: (isClientside) =>
        realm = isClientside and "client" or "server"
        url = @config.webhook[realm]
        url and= url\GetString!

        assert url and #url > 0, "[ErrorForwarder] Tried to send a webhook with no URL (#{realm}). Have you set your convars?"

        return url

    sendNext: =>
        return if @waitUntil and CurTime! < @waitUntil

        -- Stop looping if we're empty
        item = table.remove @queue, 1
        if not item
            -- We clear the saved queue now that we're empty so already-sent errors aren't sent again
            @saveQueue! if @config.backup\GetBool!
            @running = false
            return

        @logger\info "Sending Discord webhook. Queue size: #{#@queue}"

        success, err = pcall ->
            -- Fill in the rest of the request keys
            -- TODO: We'll be doing this twice for loaded queue items.
            table.Merge item, @requestTemplate

            item.url = @getUrl item.isClientside
            item.isClientside = nil
            reqwest item

        return if success

        @logger\error "Failed when calling reqwest: #{err}"
        @sendNext!

    enqueue: (item) =>
        table.insert @queue, item
        return if @running

        @running = true
        @sendNext!

    onRateLimit: (body, headers) =>
        @retryAfter = getRetryAfter body, headers
        @logger\warn "Rate limited. Continuing in #{@retryAfter} seconds."

        timer.Create "CFC_ErrForwarder_DiscordRateLimit", @retryAfter, 1, ->
            @retryAfter = nil
            @sendNext!

        @saveQueue! if @config.backup\GetBool!

    onSuccess: (code, body, headers) =>
        if code == 429
            return @onRateLimit body, headers

        if code >= 400
            @logger\error "Received failure code on webhook send: Code: #{code} | Body:\n #{body}"

        @sendNext!

    onFailure: (reason) =>
        @logger\error "Failed to send webhook: #{reason}"
        @sendNext!

    Send: (data) =>
        @enqueue
            isClientside: data.isClientside
            body: util.TableToJSON Formatter data

return DiscordInterface
