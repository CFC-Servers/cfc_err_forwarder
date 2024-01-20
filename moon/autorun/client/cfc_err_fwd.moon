hook.Add "Think", "CFC_ErrForwarder_BranchInit", ->
    hook.Remove "Think", "CFC_ErrForwarder_BranchInit"
    net.Start "cfc_err_forwarder_clbranch"
    net.WriteString BRANCH
    net.SendToServer!

bucket = 4
sendCache = {}
hook.Add "OnLuaError", "CFC_ErrForwarder_OnLuaError", (errorString, _, stack) ->
    -- TODO: Queue errors that happen before the setting has been received?
    return unless GetGlobal2Bool "CFC_ErrorForwarder_ManualSend", false

    return if bucket <= 0

    now = CurTime!
    expires = sendCache[errorString] or now
    return if expires > now
    sendCache[errorString] = now + 5

    net.Start "cfc_err_forwarder_clerror"
    net.WriteString errorString

    stackCount = math.min #stack, 7
    net.WriteUInt stackCount, 8

    for i = 1, stackCount
        level = stack[i]
        net.WriteString level.File
        net.WriteString level.Function
        net.WriteString level.Line

    net.SendToServer!

    bucket -= 1

timer.Create "CFC_ErrForwarder_BucketReset", 1, 0, ->
    bucket += 1 if bucket < 4
