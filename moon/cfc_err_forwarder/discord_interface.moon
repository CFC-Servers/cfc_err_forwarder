Formatter = include "discord_formatter.lua"

return (config) ->
    (data, success, failed) ->
        url = data.isClientside and "client" or "server"
        url = config.webhook[url]\GetString!

        reqwest
            url: url
            success: success
            failed: (err, ext) -> failed "#{err} - #{ext}"
            method: "POST"
            type: "application/json"
            headers: "User-Agent": "CFC Error Forwarder v1"
            body: util.TableToJSON Formatter data

