convertPlainStack = (stack) ->
    newStack = {}

    for i, level in ipairs stack
        newStack[i] = {
            source: level.File
            name: level.Function
            currentline: level.Line
        }

    return newStack

hook.Add "OnLuaError", "CFC_ServerErrorForwarder", (errorString, _, stack) ->
    print( "stack is nil?", stack == nil )
    stack = convertPlainStack stack

    firstLevel = stack[1]
    sourceFile = firstLevel and firstLevel.File
    sourceLine = firstLevel and firstLevel.Line

    ErrorForwarder\receiveSVError errorString, sourceFile, sourceLine, errorString, stack

getErrorStringFromFull = (fullError) =>
    errStringStart = string.find fullError, ": "

    return fullError unless errStringStart
    return string.sub fullError, errStringStart + 2

net.Receive "cfc_err_forwarder_clerror", (_, ply) ->
    return if useErrorModule

    errorString = net.ReadString!

    stackCount = net.ReadUInt 8
    stackCount = math.min stackCount, 7

    stack = {}
    for i = 1, stackCount
        stack[i] =
            source: net.ReadString!
            name: net.ReadString!
            currentline: net.ReadString!

    firstStack = stack[1]
    sourceFile = firstLevel and firstLevel.File
    sourceLine = firstLevel and firstLevel.Line

    ErrorForwarder\receiveCLError ply, errorString, sourceFile, sourceLine, errorString, stack
