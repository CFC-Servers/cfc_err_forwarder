hook.Add "InitPostEntity", "CFC_ErrForwarder_BranchInit", ->
    net.Start "cfc_err_forwarder_clbranch"
    net.WriteString BRANCH
    net.SendToServer!

hook.Add "OnLuaError", "CFC_ErrForwarder_OnLuaError", (errorString, _, stack) ->
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
