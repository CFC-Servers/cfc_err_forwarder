local baseGmodURL = "https://github.com/Facepunch/garrysmod/blob/master/garrysmod/%s#L%s"
local function getGmodURL( source, line )
    return string.format( baseGmodURL, { source = source, line = line } )
end

--- A 
local urlCache = {}
local missCache = {}

--- Builds the base URL for the given project dir
--- It is assumed that this is only called for addons
--- @param mainDir string The name of the addon's directory
--- @return string?
local function _getProjectURL( mainDir )
    local fetchPath = "addons/" .. mainDir .. "/.git/FETCH_HEAD"
    local content = file.Read( fetchPath, "GAME" )

    if not content then return nil end
    if content == "" then return nil end

    -- 6679969ce1b0f6baa80dc4460beb7004f3197408 branch 'master' of github.com:Stooberton/ACF-3
    -- 6679969ce1b0f6baa80dc4460beb7004f3197408 branch 'master' of https://github.com/Stooberton/ACF-3
    -- 6679969ce1b0f6baa80dc4460beb7004f3197408	branch 'master' of https://github.com/stooberton/acf-3.git
    local firstLine = string.Split( content, "\n" )[1]

    -- "master", "github.com:Stooberton/ACF-3"
    -- "master", "https://github.com/Stooberton/ACF-3"
    -- "master", "https://github.com/Stooberton/acf-3.git"
    local _, _, branch, repo = string.find( firstLine, "branch '(.+)' of (.+)$" )
    if not branch or not repo then return nil end --

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

    return string.format( "https://%s/%s/%s/blob/%s", host, owner, project, branch )
end

--- Cache wrapper for the _getProjectURL function
--- @param mainDir string
--- @return string?
local function getProjectURL( mainDir )
    local cached = urlCache[mainDir]

    if not cached then
        -- Break out early if this is a waste of time
        if missCache[mainDir] then return end

        cached = _getProjectURL( mainDir )

        -- If the function returned nothing, cache that result too
        if not cached then
            missCache[mainDir] = true
            return
        end

        urlCache[mainDir] = cached
    end

    return cached
end

return function( source, line )
    if not source then return end

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

    -- "https://github.com/Stooberton/ACF-3/blob/master"
    local rootURL = getProjectURL( mainDir )
    if not rootURL then
        print( "[CFC_ErrorForwarder] Couldn't find project URL for addon:", mainDir )
        return
    end

    -- "lua/entities/acf_armor/shared.lua"
    -- "sandbox/entities/weapons/gmod_stool/stools/duplicator/transport.lua"
    local finalPath = table.concat( sourceSpl, "/", 3, #sourceSpl ) .. "#L" .. line

    -- "https://github.com/Stooberton/ACF-3/blob/master/lua/entities/acf_armor/shared.lua"
    local finalURL = rootURL .. "/" .. finalPath

    return finalURL
end
