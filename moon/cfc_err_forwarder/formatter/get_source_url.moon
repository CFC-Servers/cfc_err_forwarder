-- Gamemodes hosted on Facepunch's public garrysmod repo
publicGamemodes = {
    base: true
    sandbox: true
    terrortown: true
}

-- Makes a new gist with the
-- source file and links to the given line
-- getGistLink = (source, line) ->

-- source:
--    addons/acf-3/lua/entities/acf_armor/shared.lua
--    gamemodes/sandbox/entities/weapons/gmod_tool/stools/duplicator/transport.lua
--
-- line: Just a line number
(source, line) ->
    -- { "addons", "acf-3", "lua", "entities", "acf_armor", "shared.lua" }
    -- { "gamemodes", "sandbox", "entities", "weapons", "gmod_tool", "stools", "duplicator", "transport.lua" }
    sourceSpl = string.Split source, "/"

    root = sourceSpl[1]
    mainDir = sourceSpl[2]

    if root == "gamemodes"
        return "https://github.com/Facepunch/garrysmod/blob/master/garrysmod/#{source}#L#{line}"

    assert root == "addons"

    fetchPath = "addons/#{mainDir}/.git/FETCH_HEAD", "GAME"
    return unless file.Exists fetchPath, "GAME"

    content = file.Read fetchPath, "GAME"

    -- 6679969ce1b0f6baa80dc4460beb7004f3197408 branch 'master' of github.com:Stooberton/ACF-3
    -- 6679969ce1b0f6baa80dc4460beb7004f3197408 branch 'master' of https://github.com/Stooberton/ACF-3
    -- 6679969ce1b0f6baa80dc4460beb7004f3197408	branch 'master' of https://github.com/stooberton/acf-3.git
    firstLine = string.Split(content, "\n")[1]

    -- "master", "github.com:Stooberton/ACF-3"
    -- "master", "https://github.com/Stooberton/ACF-3"
    -- "master", "https://github.com/Stooberton/acf-3.git"
    _, _, branch, repo = string.find firstLine, "branch '(.+)' of (.+)$"

    -- "github.com/Stooberton/ACF-3"
    repo = string.Replace repo, "https://", ""
    repo = string.Replace repo, "http://", ""
    repo = string.Replace repo, ":", "/"
    repo = string.Replace repo, ".git", ""

    -- { "github.com", "Stooberton", "ACF-3" }
    repoSpl = string.Split repo, "/"

    -- "github.com"
    host = repoSpl[1]

    -- "Stooberton"
    owner = repoSpl[2]

    -- "ACF-3"
    project = repoSpl[3]

    -- "lua/entities/acf_armor/shared.lua"
    -- "sandbox/entities/waepons/gmod_stool/stools/duplicator/transport.lua"
    finalPath = table.concat sourceSpl, "/", 3, #sourceSpl
    finalPath ..= "#L#{line}"

    finalURL = string.format "https://%s/%s/%s/blob/%s/%s", host, owner, project, branch, finalPath

    return finalURL
