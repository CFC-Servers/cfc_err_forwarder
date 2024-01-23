local Config
Config = CFCErrForwarder.Config
local GIST_URL = "https://api.github.com/gists?scope=gist"
return function(content)
  local timestamp = os.time()
  local niceDate = os.date("%H:%M:%S - %d/%m/%Y", timestamp)
  local success, status, body, headers = reqwest({
    url = GIST_URL,
    blocking = true,
    headers = {
      ["Authorization"] = "token " .. tostring(token)
    },
    payload = util.TableToJSON({
      public = false,
      files = {
        ["error_" .. tostring(timestamp)] = {
          content = content
        }
      },
      description = "Error occurred: " .. tostring(niceDate)
    })
  })
  if success then
    local link = util.JSONToTable(body)
    return link["html_url"]
  end
  ErrorNoHaltWithStack("Failed to create Gist!")
  Logger:warn("Status: ", status)
  return Logger:warn("Body: ", body)
end
