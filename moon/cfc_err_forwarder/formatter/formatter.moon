red = 14483456
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
    emoji = client and "🟨" or "🟦"
    realm = client and "Client" or "Server"

    {
        content: ""
        embeds: {
            {
                color: red
                title: "#{emoji} #{realm} Error"
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
