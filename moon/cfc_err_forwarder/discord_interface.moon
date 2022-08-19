import Config from CFCErrForwarder

formatter = include "discord_formatter.lua"

return (data) ->
    url = data.isClientside and "Clientside" or "Serverside"
    url = Config.webhook[url]

    reqwest
        url: url
        method: "POST"
        type: "application/json"
        headers: "User-Agent": "CFC Error Forwarder v1"
        body: util.TableToJSON Formatter data
