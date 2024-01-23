local Logger, Forwarder, Config
local bucketSize = CreateConVar("cfc_err_forwarder_bucket_size", "5", FCVAR_ARCHIVE)
local convertPlainStack
convertPlainStack = function(stack)
  local newStack = { }
  for i, level in ipairs(stack) do
    newStack[i] = {
      source = level.File,
      name = level.Function,
      currentline = level.Line
    }
  end
  return newStack
end
local getErrorStringFromFull
getErrorStringFromFull = function(fullError)
  local errStringStart = string.find(fullError, ": ")
  if not (errStringStart) then
    return fullError
  end
  return string.sub(fullError, errStringStart + 2)
end
hook.Add("OnLuaError", "CFC_ServerErrorForwarder", function(fullError, realm, stack)
  stack = convertPlainStack(stack)
  local errorString = getErrorStringFromFull(fullError)
  local firstLevel = stack[1]
  local sourceFile = firstLevel and firstLevel.source
  local sourceLine = firstLevel and firstLevel.currentline
  return Forwarder:receiveSVError(true, fullError, sourceFile, sourceLine, errorString, stack)
end)
local buckets = { }
local errCache = { }
net.Receive("cfc_err_forwarder_clerror", function(len, ply)
  if useErrorModule then
    return 
  end
  local plyBucket = buckets[ply]
  if plyBucket <= 0 then
    return 
  end
  buckets[ply] = plyBucket - 1
  if len > 4096 then
    Logger:warn("Error too long (abuse?), skipping " .. tostring(len) .. "-byte error from", ply)
    return 
  end
  local fullError = net.ReadString()
  local expires = errCache[fullError]
  local now = CurTime()
  if expires and expires > now then
    return 
  end
  errCache[fullError] = now + 5
  local errorString = getErrorStringFromFull(fullError)
  local stackCount = net.ReadUInt(8)
  stackCount = math.min(stackCount, 7)
  local stack = { }
  local sourceFile, sourceLine
  for i = 1, stackCount do
    local source = net.ReadString()
    local name = net.ReadString()
    local currentline = net.ReadString()
    stack[i] = {
      source = source,
      name = name,
      currentline = currentline
    }
    if sourceFile == nil or sourceFile == "[C]" then
      sourceFile = source
      sourceLine = currentline
    end
  end
  local shouldForward = hook.Run("CFC_ErrorForwarder_OnReceiveCLError", ply, fullError, sourceFile, sourceLine, errorString, stack)
  if shouldForward == false then
    return 
  end
  return Forwarder:receiveCLError(ply, fullError, sourceFile, sourceLine, errorString, stack)
end)
timer.Create("CFC_ErrForwarder_BucketReset", 1, 0, function()
  for ply, bucket in pairs(buckets) do
    if ply:IsValid() then
      if bucket < Config.bucketSize:GetInt() then
        buckets[ply] = bucket + 1
      end
    else
      buckets[ply] = nil
    end
  end
end)
hook.Add("PlayerInitialSpawn", "CFC_ErrForwarder_BucketReset", function(ply)
  buckets[ply] = Config.bucketSize:GetInt()
end)
return function(SetLogger, SetForwarder, SetConfig)
  Logger = SetLogger
  Forwarder = SetForwarder
  Config = SetConfig
end
