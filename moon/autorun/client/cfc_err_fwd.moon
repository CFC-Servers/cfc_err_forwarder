hook.Add "InitPostEntity", "CFC_ErrForwarder_BranchInit", ->
    net.Start "cfc_err_forwarder_clbranch"
    net.WriteString BRANCH
    net.SendToServer!
