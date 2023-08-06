local baseGmodURL = "https://github.com/Facepunch/garrysmod/blob/master/garrysmod/%s#L%s"
local function getGmodURL( source, line )
    return string.format( baseGmodURL, { source = source, line = line } )
end

return function( source, line )
    -- { "addons", "acf-3", "lua", "entities", "acf_armor", "shared.lua" }
    -- { "gamemodes", "sandbox", "entities", "weapons", "gmod_tool", "stools", "duplicator", "transport.lua" }
    local sourceSpl = string.Split( source, "/" )

    if sourceSpl[1] == "gamemodes" then
        return getGmodURL( source, line )
    end

    if sourceSpl[1] == "addons" then
        local fetchPath = "addons/" .. sourceSpl[2] .. "/.git/FETCH_HEAD"

        if not file.Exists( fetchPath, "GAME" ) then
            return nil
        end

        local content = file.Read( fetchPath, "GAME" )
        local firstLine = string.Split( content, "\n" )[1]

        local _, _, branch, repo = string.find( firstLine, "branch '(.+)' of (.+)$" )

        repo = string.gsub( repo, "https://", "" )
        repo = string.gsub( repo, "http://", "" )
        repo = string.gsub( repo, ":", "/" )

        local repoSpl = string.Split( repo, "/" )
        local host = repoSpl[1]
        local owner = repoSpl[2]
        local project = repoSpl[3]

        local finalPath = table.concat( sourceSpl, "/", 3, #sourceSpl ) .. "#L" .. line
        local finalURL = string.format( "https://%s/%s/%s/blob/%s/%s", host, owner, project, branch, finalPath )

        return finalURL
    end
end
