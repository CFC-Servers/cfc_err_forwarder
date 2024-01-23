hook.Add("Think", "CFC_ErrForwarder_BranchInit", function()
  hook.Remove("Think", "CFC_ErrForwarder_BranchInit")
  net.Start("cfc_err_forwarder_clbranch")
  net.WriteString(BRANCH)
  return net.SendToServer()
end)
local bucket = 4
local sendCache = { }
hook.Add("OnLuaError", "CFC_ErrForwarder_OnLuaError", function(errorString, _, stack)
  if not (GetGlobal2Bool("CFC_ErrorForwarder_ManualSend", false)) then
    return 
  end
  if bucket <= 0 then
    return 
  end
  local now = CurTime()
  local expires = sendCache[errorString] or now
  if expires > now then
    return 
  end
  sendCache[errorString] = now + 5
  net.Start("cfc_err_forwarder_clerror")
  net.WriteString(errorString)
  local stackCount = math.min(#stack, 7)
  net.WriteUInt(stackCount, 8)
  for i = 1, stackCount do
    local level = stack[i]
    net.WriteString(level.File)
    net.WriteString(level.Function)
    net.WriteString(level.Line)
  end
  net.SendToServer()
  bucket = bucket - 1
end)
return timer.Create("CFC_ErrForwarder_BucketReset", 1, 0, function()
  if bucket < 4 then
    bucket = bucket + 1
  end
end)
