Formatter = include "formatter/formatter.lua"

return (config) ->
    (data, onSuccess, onFailure) ->
        url = data.isClientside and "client" or "server"
        url = config.webhook[url]\GetString!

        body = Formatter data

        failed = (err, ext) -> onFailure "#{err} - #{ext}"
        success = (status, body) ->
            if status < 200 or status > 299
                return failed status, body
            onSuccess!

        reqwest
            url: url
            success: success
            failed: failed
            method: "POST"
            type: "application/json"
            headers: "User-Agent": "CFC Error Forwarder v1"
            body: util.TableToJSON body
