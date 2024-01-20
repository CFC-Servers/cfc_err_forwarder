clientColor = 14592265
serverColor = 240116
locals = include "locals.lua"
niceStack = include "nice_stack.lua"

import
    bad, bold, getSourceText, code,
    steamIDLink, truncate, timestamp,
    gmodBranch
    from include "text_helpers.lua"

nonil = (t) -> [v for v in *t when v ~= nil]

(data) ->
    client = data.isClientside
    realm = client and "Client" or "Server"

    {
        content: ""
        embeds: {
            {
                color: client and clientColor or serverColor
                title: "#{realm} Error"
                author: name: GetHostName!
                description: bad data.errorString
                fields: nonil {
                    with source = getSourceText data
                        return { name: "Source File", value: source } if source
                        return nil

                    {
                        name: "Full Error"
                        value: code truncate client and data.fullError or niceStack data
                    }

                    with l = locals data
                        return { name: "Locals", value: code truncate(l), "m"  } if l

                    with {:ply, :plyName, :plySteamID} = data
                        return { name: "Player", value: bold "#{plyName} ( #{steamIDLink plySteamID} )" } if ply
                        return nil

                    with {:branch} = data
                        return { name: "Branch", value: bold "`#{gmodBranch branch}`", inline: true } if branch
                        return nil

                    {
                        name: "Count"
                        value: bold data.count
                        inline: true
                    }

                    {
                        name: "Most recent occurrence"
                        value: timestamp data.occurredAt
                        inline: true
                    }
                }
            }
        }
    }
