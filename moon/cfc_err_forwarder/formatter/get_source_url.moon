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
--    addons/cfc_pvp/lua/cfc_pvp/plugins/server/acf_caliber_limits.lua
--    gamemodes/sandbox/entities/weapons/gmod_tool/stools/duplicator/transport.lua
--
-- line: Just a number, nothing crazy
(source, line) ->
    -- { "addons", "acf-3", "lua", "entities", "acf_armor", "shared.lua" }
    -- { "gamemodes", "sandbox", "entities", "weapons", "gmod_tool", "stools", "duplicator", "transport.lua" }
    sourceSpl = string.Split source, "/"

    if sourceSpl[1] == "gamemodes"
        return "https://github.com/Facepunch/garrysmod/blob/master/garrysmod/#{source}#L#{line}"

    if sourceSpl[1] == "addons"
        fetchPath = "addons/#{sourceSpl[2]}/.git/FETCH_HEAD", "GAME"

        return unless file.Exists fetchPath, "GAME"

        content = file.Read fetchPath, "GAME"
        firstLine = string.Split(content, "\n")[1]

        _, _, branch, repo = string.find firstLine, "branch '(.+)' of (.+)$"

        repo = string.Replace repo, "https://", ""
        repo = string.Replace repo, "http://", ""
        repo = string.Replace repo, ":", "/"

        repoSpl = string.Split repo, "/"
        host = repoSpl[1]
        owner = repoSpl[2]
        project = repoSpl[3]

        finalPath = table.concat sourceSpl, "/", 3, #sourceSpl
        finalPath ..= "#L#{line}"

        finalURL = string.format "https://%s/%s/%s/blob/%s/%s", host, owner, project, branch, finalPath

        return finalURL
