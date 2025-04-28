ErrorForwarder.ClientErrorQueue = ErrorForwarder.ClientErrorQueue or {}
ErrorForwarder.ClientErrorsLogged = ErrorForwarder.ClientErrorsLogged or {}
ErrorForwarder.ClientNetReady = ErrorForwarder.ClientNetReady or false

hook.Add( "OnLuaError", "CFC_RuntimeErrorForwarder", function( err, _, stack )
    local errorHash = util.CRC( err .. util.TableToJSON( stack ) )
    if ErrorForwarder.ClientErrorsLogged[errorHash] then return end
    ErrorForwarder.ClientErrorsLogged[errorHash] = true

    table.insert( ErrorForwarder.ClientErrorQueue, {
        err = err,
        stack = stack,
    } )
end )

timer.Create( "CFC_ClientErrorForwarder", 11, 0, function()
    if not ErrorForwarder.ClientNetReady then return end
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

timer.Create( "CFC_ClientErrorForwarder_Init", 1, 0, function()
    if not IsValid( LocalPlayer() ) then return end
    timer.Remove( "CFC_ClientErrorForwarder_Init" )
    ErrorForwarder.ClientNetReady = true
end )
