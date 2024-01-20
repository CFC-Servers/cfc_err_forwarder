-- Gamemodes hosted on Facepunch's public garrysmod repo
publicGamemodes = {
    base: true
    sandbox: true
    terrortown: true
}

-- Makes a new gist with the
-- source file and links to the given line
-- getGistLink = (source, line) ->

parseRepoURL = (repo) ->
    -- "git@github.com:wiremod/wire.git"
    -- "github.com/Stooberton/ACF-3"

    repo = string.Replace repo, "https://", ""
    repo = string.Replace repo, "http://", ""
    repo = string.Replace repo, ":", "/"
    repo = string.Replace repo, ".git", ""
    repo = string.Replace repo, "git@", ""

    -- { "github.com", "wiremod", "wire" }
    -- { "github.com", "Stooberton", "ACF-3" }
    repoSpl = string.Split repo, "/"

    -- "github.com"
    -- "github.com"
    host = repoSpl[1]

    -- "wiremod"
    -- "Stooberton"
    owner = repoSpl[2]

    -- "wire"
    -- "ACF-3"
    project = repoSpl[3]

    return { :host, :owner, :project }

configParser = include "git_config_parser.lua"
parseHead = (gitPath) ->
    local branch

    do
        -- ref: refs/heads/master
        content = file.Read "#{gitPath}/HEAD", "GAME"
        return unless content

        -- "master"
        branch = string.match content, "ref: refs/%w+/(%w+)"

    content = file.Read "#{gitPath}/config", "GAME"
    return unless content

    config = configParser content

    -- { remote: "origin", merge: "refs/heads/master" }
    branchInfo = config.branch[branch]
    remoteInfo = config.remote[branchInfo.remote]

    -- "git@github.com:wiremod/wire.git"
    repo = remoteInfo.url

    parsed = parseRepoURL repo
    parsed.branch = branch

    return parsed


parseFetchHead = (gitPath) ->
    fetchPath = "#{gitPath}/FETCH_HEAD"
    content = file.Read fetchPath, "GAME"
    return unless content

    -- 6679969ce1b0f6baa80dc4460beb7004f3197408 branch 'master' of github.com:Stooberton/ACF-3
    -- 6679969ce1b0f6baa80dc4460beb7004f3197408 branch 'master' of https://github.com/Stooberton/ACF-3
    -- 6679969ce1b0f6baa80dc4460beb7004f3197408	branch 'master' of https://github.com/stooberton/acf-3.git
    firstLine = string.Split(content, "\n")[1]

    -- "master", "github.com:Stooberton/ACF-3"
    -- "master", "https://github.com/Stooberton/ACF-3"
    -- "master", "https://github.com/Stooberton/acf-3.git"
    _, _, branch, repo = string.find firstLine, "branch '(.+)' of (.+)$"

    parsed = parseRepoURL repo
    parsed.branch = branch

    return parsed

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

    -- If the root isn't a Gamemode or Addon, we can't get a source URL for it
    return if root ~= "addons"

    gitPath = "addons/#{mainDir}/.git"
    return unless file.Exists gitPath, "GAME"

    sourceData = parseFetchHead gitPath
    sourceData or= parseHead gitPath
    return unless sourceData

    { :host, :owner, :project, :branch } = sourceData

    -- "lua/entities/acf_armor/shared.lua"
    -- "sandbox/entities/waepons/gmod_stool/stools/duplicator/transport.lua"
    finalPath = table.concat sourceSpl, "/", 3, #sourceSpl
    finalPath ..= "#L#{line}"

    finalURL = string.format "https://%s/%s/%s/blob/%s/%s", host, owner, project, branch, finalPath

    return finalURL
