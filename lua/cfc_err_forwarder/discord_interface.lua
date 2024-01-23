local Formatter = include("formatter/formatter.lua")
return function(config)
  return function(data, onSuccess, onFailure)
    local url = data.isClientside and "client" or "server"
    url = config.webhook[url]:GetString()
    local body = Formatter(data)
    local failed
    failed = function(err, ext)
      return onFailure(tostring(err) .. " - " .. tostring(ext))
    end
    local success
    success = function(status, body)
      if status < 200 or status > 299 then
        return failed(status, body)
      end
      return onSuccess()
    end
    return reqwest({
      url = url,
      success = success,
      failed = failed,
      method = "POST",
      type = "application/json",
      headers = {
        ["User-Agent"] = "CFC Error Forwarder v1"
      },
      body = util.TableToJSON(body)
    })
  end
end
