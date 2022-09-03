red = 14483456
locals = include "locals.lua"
niceStack = include "nice_stack.lua"

import
    bad, bold, getSourceText,
    code, steamIDLink, truncate,
    timestamp, humanTimestamp
    from include "text_helpers.lua"

nonil = (t) -> [v for v in *t when v ~= nil]

(data) ->
    client = data.isClientside
    realm = client and "Client" or "Server"

    {
        content: ""
        embeds: {
            {
                color: red
                timestamp: timestamp!
                title: "#{realm} Error"
                author: name: GetHostName!
                description: bad data.errorString
                fields: nonil {
                    {
                        name: "Source File"
                        value: getSourceText data
                    }

                    {
                        name: "Full Error"
                        value: code truncate client and data.fullError or niceStack data
                    }

                    with l = locals data
                        return { name: "Locals", value: code truncate(l), "m"  } if l

                    with {:ply, :plyName, :plySteamID} = data
                        return { name: "Player", value: bold "#{plyName} ( #{steamIDLink plySteamID} )" } if ply
                        return nil

                    {
                        name: "Count"
                        value: bold data.count
                        inline: true
                    }

                    {
                        name: "Most recent occurrence"
                        value: code humanTimestamp data.occurredAt
                        inline: true
                    }
                }
            }
        }
    }
