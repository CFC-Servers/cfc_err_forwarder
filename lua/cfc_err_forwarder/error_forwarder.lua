local Count
Count = table.Count
local osTime = os.time
local istable = istable
local pretty = include("cfc_err_forwarder/formatter/pretty_values.lua")
local removeCyclic
removeCyclic = function(tbl, found)
  if found == nil then
    found = { }
  end
  if found[tbl] then
    return 
  end
  found[tbl] = true
  for k, v in pairs(tbl) do
    local _continue_0 = false
    repeat
      if not (istable(v)) then
        _continue_0 = true
        break
      end
      if found[v] then
        print("Found cyclic table, key: " .. tostring(k) .. " | value: " .. tostring(v) .. " | table: " .. tostring(tbl))
        tbl[k] = nil
      else
        removeCyclic(v, found)
      end
      _continue_0 = true
    until true
    if not _continue_0 then
      break
    end
  end
end
local stripStack
stripStack = function(tbl)
  for _, stackObj in pairs(tbl) do
    stackObj.upvalues = nil
    stackObj.activelines = nil
  end
end
local stringTable
stringTable = function(tbl)
  local oneline = table.Count(tbl) == 1
  local str = "{"
  if not (oneline) then
    str = str .. "\n"
  end
  local count = 0
  for k, v in pairs(tbl) do
    if count >= 5 then
      break
    end
    str = str .. "  " .. tostring(k) .. " = " .. tostring(pretty(v))
    str = str .. (oneline and " " or "\n")
    count = count + 1
  end
  str = str .. "}"
  return str
end
local saveLocals
saveLocals = function(stack)
  for _, stackObj in pairs(stack) do
    local _continue_0 = false
    repeat
      local locals = stackObj.locals
      if not (locals) then
        _continue_0 = true
        break
      end
      local newLocals = { }
      for name, value in pairs(locals) do
        if istable(value) then
          newLocals[name] = stringTable(value)
        else
          newLocals[name] = pretty(value)
          local newLocal = newLocals[name]
          if #newLocal > 125 then
            newLocals[name] = tostring(string.Left(newLocal, 122)) .. "..."
          end
        end
      end
      stackObj.locals = newLocals
      _continue_0 = true
    until true
    if not _continue_0 then
      break
    end
  end
end
local ErrorForwarder
do
  local _class_0
  local _base_0 = {
    countQueue = function(self)
      return Count(self.queue)
    end,
    errorIsQueued = function(self, fullError)
      return self.queue[fullError] ~= nil
    end,
    addPlyToObject = function(self, errorStruct, ply)
      errorStruct.player = {
        playerName = ply:Name(),
        playerSteamID = ply:SteamID()
      }
      return errorStruct
    end,
    queueError = function(self, isRuntime, fullError, sourceFile, sourceLine, errorString, stack, ply)
      local count = 1
      local occurredAt = osTime()
      local isClientside = ply ~= nil
      local locals = saveLocals(stack)
      local plyName
      local plySteamID
      local branch
      if ply then
        plyName = ply:Nick()
        plySteamID = ply:SteamID()
        branch = ply.CFC_ErrorForwarder_CLBranch or "Not sure yet"
      else
        branch = BRANCH
      end
      local newError = {
        count = count,
        errorString = errorString,
        fullError = fullError,
        isRuntime = isRuntime,
        occurredAt = occurredAt,
        sourceFile = sourceFile,
        sourceLine = sourceLine,
        stack = stack,
        isClientside = isClientside,
        ply = ply,
        plyName = plyName,
        plySteamID = plySteamID,
        branch = branch,
        reportInterval = self.config.groomInterval:GetInt()
      }
      if isClientside then
        newError = self:addPlyToObject(newError, ply)
      end
      local shouldQueue = hook.Run("CFC_ErrorForwarder_PreQueue", newError)
      if shouldQueue == false then
        return 
      end
      self.logger:debug("Inserting error into queue: '" .. tostring(fullError) .. "'")
      self.queue[fullError] = newError
    end,
    unqueueError = function(self, fullError)
      local thisErr = self.queue[fullError]
      if thisErr then
        for k in pairs(thisErr) do
          thisErr[k] = nil
        end
      end
      self.queue[fullError] = nil
    end,
    incrementError = function(self, fullError)
      local thisErr = self.queue[fullError]
      local count = thisErr.count
      thisErr.count = count + 1
      thisErr.occurredAt = osTime()
    end,
    receiveError = function(self, isRuntime, fullError, sourceFile, sourceLine, errorString, stack, ply)
      if self:errorIsQueued(fullError) then
        return self:incrementError(fullError)
      end
      return self:queueError(isRuntime, fullError, sourceFile, sourceLine, errorString, stack, ply)
    end,
    logErrorInfo = function(self, isRuntime, fullError, sourceFile, sourceLine, errorString, stack)
      local debug
      do
        local _base_1 = self.logger
        local _fn_0 = _base_1.debug
        debug = function(...)
          return _fn_0(_base_1, ...)
        end
      end
      debug("Is Runtime: " .. tostring(isRuntime))
      debug("Full Error: " .. tostring(fullError))
      debug("Source File: " .. tostring(sourceFile))
      debug("Source Line: " .. tostring(sourceLine))
      return debug("Error String: " .. tostring(errorString))
    end,
    receiveSVError = function(self, isRuntime, fullError, sourceFile, sourceLine, errorString, stack)
      self.logger:debug("Received Serverside Lua Error: " .. tostring(errorString))
      self:logErrorInfo(isRuntime, fullError, sourceFile, sourceLine, errorString, stack)
      return self:receiveError(isRuntime, fullError, sourceFile, sourceLine, errorString, stack)
    end,
    receiveCLError = function(self, ply, fullError, sourceFile, sourceLine, errorString, stack)
      if not (ply and ply:IsPlayer()) then
        return 
      end
      if not (self.config.clientEnabled:GetBool()) then
        return 
      end
      self.logger:debug("Received Clientside Lua Error for " .. tostring(ply:SteamID()) .. " (" .. tostring(ply:Name()) .. "): " .. tostring(errorString))
      self:logErrorInfo(true, fullError, sourceFile, sourceLine, errorString, stack)
      return self:receiveError(true, fullError, sourceFile, sourceLine, errorString, stack, ply)
    end,
    cleanStruct = function(self, errorStruct)
      stripStack(errorStruct.stack)
      return errorStruct
    end,
    forwardError = function(self, errorStruct, onSuccess, onFailure)
      self.logger:debug("Sending error object..")
      return self.discord(errorStruct, onSuccess, onFailure)
    end,
    forwardErrors = function(self)
      for errorString, data in pairs(self.queue) do
        local _continue_0 = false
        repeat
          self.logger:debug("Processing queued error: " .. tostring(errorString))
          local errorData = self:cleanStruct(data)
          local onSuccess
          onSuccess = function()
            return self:onSuccess(errorString)
          end
          local onFailure
          onFailure = function(failure)
            return self:onFailure(errorString, failure, errorData)
          end
          local success, err = pcall(function()
            return self:forwardError(errorData, onSuccess, onFailure)
          end)
          if success then
            _continue_0 = true
            break
          end
          onFailure(err)
          _continue_0 = true
        until true
        if not _continue_0 then
          break
        end
      end
    end,
    groomQueue = function(self)
      local count = self:countQueue()
      if count == 0 then
        return 
      end
      self.logger:debug("Grooming Error Queue of size: " .. tostring(count))
      return self:forwardErrors()
    end,
    onSuccess = function(self, fullError)
      self.logger:debug("Successfully sent error", fullError)
      return self:unqueueError(fullError)
    end,
    onFailure = function(self, fullError, failure, errorData)
      self.logger:error("Failed to send error!", failure)
      self:unqueueError(fullError)
      return print(util.TableToJSON({
        failedErrorData = errorData
      }))
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, logger, discord, config)
      self.logger = logger
      self.discord = discord
      self.config = config
      self.queue = { }
    end,
    __base = _base_0,
    __name = "ErrorForwarder"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  ErrorForwarder = _class_0
  return _class_0
end
