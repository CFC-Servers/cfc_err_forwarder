local publicGamemodes = {
  base = true,
  sandbox = true,
  terrortown = true
}
local parseRepoURL
parseRepoURL = function(repo)
  repo = string.Replace(repo, "https://", "")
  repo = string.Replace(repo, "http://", "")
  repo = string.Replace(repo, ":", "/")
  repo = string.Replace(repo, ".git", "")
  repo = string.Replace(repo, "git@", "")
  local repoSpl = string.Split(repo, "/")
  local host = repoSpl[1]
  local owner = repoSpl[2]
  local project = repoSpl[3]
  return {
    host = host,
    owner = owner,
    project = project
  }
end
local configParser = include("git_config_parser.lua")
local parseHead
parseHead = function(gitPath)
  local branch
  do
    local content = file.Read(tostring(gitPath) .. "/HEAD", "GAME")
    if not (content) then
      return 
    end
    branch = string.match(content, "ref: refs/%w+/(.+)$")
    branch = string.Replace(branch, "\n", "")
  end
  local content = file.Read(tostring(gitPath) .. "/config", "GAME")
  if not (content) then
    return 
  end
  local config = configParser(content)
  local remoteInfo = config.remote.origin
  local repo = remoteInfo.url
  local parsed = parseRepoURL(repo)
  parsed.branch = branch
  return parsed
end
local parseFetchHead
parseFetchHead = function(gitPath)
  local fetchPath = tostring(gitPath) .. "/FETCH_HEAD"
  local content = file.Read(fetchPath, "GAME")
  if not (content) then
    return 
  end
  local firstLine = string.Split(content, "\n")[1]
  local _, branch, repo
  _, _, branch, repo = string.find(firstLine, "branch '(.+)' of (.+)$")
  local parsed = parseRepoURL(repo)
  parsed.branch = branch
  return parsed
end
return function(source, line)
  local sourceSpl = string.Split(source, "/")
  local root = sourceSpl[1]
  local mainDir = sourceSpl[2]
  if root == "gamemodes" then
    return "https://github.com/Facepunch/garrysmod/blob/master/garrysmod/" .. tostring(source) .. "#L" .. tostring(line)
  end
  if root ~= "addons" then
    return 
  end
  local gitPath = "addons/" .. tostring(mainDir) .. "/.git"
  if not (file.Exists(gitPath, "GAME")) then
    return 
  end
  local sourceData = parseFetchHead(gitPath)
  sourceData = sourceData or parseHead(gitPath)
  if not (sourceData) then
    return 
  end
  local host, owner, project, branch
  host, owner, project, branch = sourceData.host, sourceData.owner, sourceData.project, sourceData.branch
  local finalPath = table.concat(sourceSpl, "/", 3, #sourceSpl)
  finalPath = finalPath .. "#L" .. tostring(line)
  local finalURL = string.format("https://%s/%s/%s/blob/%s/%s", host, owner, project, branch, finalPath)
  return finalURL
end
