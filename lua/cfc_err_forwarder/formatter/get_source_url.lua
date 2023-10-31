local baseGmodURL = "https://github.com/Facepunch/garrysmod/blob/master/garrysmod/%s#L%s"
local function getGmodURL( source, line )
    return string.format( baseGmodURL, { source = source, line = line } )
end

return function( source, line )
    -- { "addons", "acf-3", "lua", "entities", "acf_armor", "shared.lua" }
    -- { "gamemodes", "sandbox", "entities", "weapons", "gmod_tool", "stools", "duplicator", "transport.lua" }
    local sourceSpl = string.Split( source, "/" )

    -- "addons"
    -- "gamemodes"
    local root = sourceSpl[1]

    -- "acf-3"
    -- "sandbox"
    local mainDir = sourceSpl[2]

    if root == "gamemodes" then
        return getGmodURL( source, line )
    end

    -- If the root isn't a Gamemode or Addon, we can't get a source URL for it
    if root ~= "addons" then return end

    local fetchPath = "addons/" .. mainDir .. "/.git/FETCH_HEAD"
    local content = file.Read( fetchPath, "LUA" )

    if not content then return nil end

    -- 6679969ce1b0f6baa80dc4460beb7004f3197408 branch 'master' of github.com:Stooberton/ACF-3
    -- 6679969ce1b0f6baa80dc4460beb7004f3197408 branch 'master' of https://github.com/Stooberton/ACF-3
    -- 6679969ce1b0f6baa80dc4460beb7004f3197408	branch 'master' of https://github.com/stooberton/acf-3.git
    local firstLine = string.Split( content, "\n" )[1]

    -- "master", "github.com:Stooberton/ACF-3"
    -- "master", "https://github.com/Stooberton/ACF-3"
    -- "master", "https://github.com/Stooberton/acf-3.git"
    local _, _, branch, repo = string.find( firstLine, "branch '(.+)' of (.+)$" )

    -- "github.com/Stooberton/ACF-3"
    repo = string.gsub( repo, "https://", "" )
    repo = string.gsub( repo, "http://", "" )
    repo = string.gsub( repo, ":", "/" )
    repo = string.gsub( repo, ".git", "" )

    -- { "github.com", "Stooberton", "ACF-3" }
    local repoSpl = string.Split( repo, "/" )

    -- "github.com"
    local host = repoSpl[1]

    -- "Stooberton"
    local owner = repoSpl[2]

    -- "ACF-3"
    local project = repoSpl[3]

    -- "lua/entities/acf_armor/shared.lua"
    -- "sandbox/entities/waepons/gmod_stool/stools/duplicator/transport.lua"
    local finalPath = table.concat( sourceSpl, "/", 3, #sourceSpl ) .. "#L" .. line
    local finalURL = string.format( "https://%s/%s/%s/blob/%s/%s", host, owner, project, branch, finalPath )

    return finalURL
end
