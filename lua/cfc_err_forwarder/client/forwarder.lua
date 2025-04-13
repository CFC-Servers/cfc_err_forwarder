if util.NetworkStringToID( "cfc_errorforwarder_clienterror" ) == 0 then return end -- Server doesn't have clientside error forwarding enabled.

ErrorForwarder.ClientErrorQueue = ErrorForwarder.ClientErrorQueue or {}
ErrorForwarder.ClientErrorsLogged = ErrorForwarder.ClientErrorsLogged or {}

hook.Add( "OnLuaError", "CFC_RuntimeErrorForwarder", function( err, _, stack )
    local errorHash = util.CRC( err .. util.TableToJSON( stack ) )
    if ErrorForwarder.ClientErrorsLogged[errorHash] then return end
    ErrorForwarder.ClientErrorsLogged[errorHash] = true

    table.insert( ErrorForwarder.ClientErrorQueue, {
        err = err,
        stack = stack,
    } )
end )

local function createTimer()
    ErrorForwarder.CreatedClientErrorTimer = true
    timer.Create( "CFC_ClientErrorForwarder", 6, 0, function()
        if #ErrorForwarder.ClientErrorQueue == 0 then return end

        local errorData = table.remove( ErrorForwarder.ClientErrorQueue, 1 )
        local err = errorData.err
        local stack = errorData.stack

        net.Start( "cfc_errorforwarder_clienterror" )
        net.WriteString( err )
        net.WriteUInt( #stack, 4 )
        for _, traceLevel in ipairs( stack ) do
            net.WriteString( traceLevel.File or "" )
            net.WriteString( traceLevel.Function or "" )
            net.WriteInt( traceLevel.Line or 0, 16 )
        end

        net.SendToServer()
    end )
end

if ErrorForwarder.CreatedClientErrorTimer then -- Autorefresh
    createTimer()
end

hook.Add( "InitPostEntity", "CFC_ClientErrorForwarder", function()
    hook.Remove( "InitPostEntity", "CFC_ClientErrorForwarder" )
    createTimer()
end )
