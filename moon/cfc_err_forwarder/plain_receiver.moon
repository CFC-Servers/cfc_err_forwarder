local Logger, Forwarder, Config

bucketSize = CreateConVar "cfc_err_forwarder_bucket_size", "5", FCVAR_ARCHIVE

convertPlainStack = (stack) ->
    newStack = {}

    for i, level in ipairs stack
        newStack[i] = {
            source: level.File
            name: level.Function
            currentline: level.Line
        }

    return newStack

getErrorStringFromFull = (fullError) ->
    errStringStart = string.find fullError, ": "

    return fullError unless errStringStart
    return string.sub fullError, errStringStart + 2

hook.Add "OnLuaError", "CFC_ServerErrorForwarder", (fullError, realm, stack) ->
    stack = convertPlainStack stack
    errorString = getErrorStringFromFull fullError

    firstLevel = stack[1]
    sourceFile = firstLevel and firstLevel.source
    sourceLine = firstLevel and firstLevel.currentline

    Forwarder\receiveSVError true, fullError, sourceFile, sourceLine, errorString, stack

-- We have to add our own protections when we send the errors manually.
-- The inbuilt client -> server error functionality has some spam protection checks built-in
-- It appears to have three major checks:
-- 1. It has some kind of length limits, whether on purpose or as a side effect
-- 2. There appears to be some kind of bucket-y rate limiting
-- 3. Duplicate errors seem to be cached and ignored, but only for a certain period of time (unclear if this is per player or overall)

buckets = {}
errCache = {}
net.Receive "cfc_err_forwarder_clerror", (len, ply) ->
    return if useErrorModule

    -- Rate limiting
    plyBucket = buckets[ply]
    return if plyBucket <= 0
    buckets[ply] = plyBucket - 1

    -- Ignoring malformed
    -- Even when trying, I wasn't able to produce a message larger than 4096 bytes in the default error transport
    if len > 4096
        Logger\warn "Error too long (abuse?), skipping #{len}-byte error from", ply
        return

    fullError = net.ReadString!
    expires = errCache[fullError]

    -- Ignoring duplicate errors
    now = CurTime!
    return if expires and expires > now
    errCache[fullError] = now + 5

    errorString = getErrorStringFromFull fullError

    stackCount = net.ReadUInt 8
    stackCount = math.min stackCount, 7

    stack = {}
    for i = 1, stackCount
        stack[i] =
            source: net.ReadString!
            name: net.ReadString!
            currentline: net.ReadString!

    firstLevel = stack[1]
    sourceFile = firstLevel and firstLevel.source
    sourceLine = firstLevel and firstLevel.currentline

    shouldForward = hook.Run "CFC_ErrorForwarder_OnReceiveCLError", ply, fullError, sourceFile, sourceLine, errorString, stack
    return if shouldForward == false

    Forwarder\receiveCLError ply, fullError, sourceFile, sourceLine, errorString, stack

timer.Create "CFC_ErrForwarder_BucketReset", 1, 0, ->
    for ply, bucket in pairs buckets
        if ply\IsValid!
            buckets[ply] = bucket + 1 if bucket < Config.bucketSize\GetInt!
        else
            buckets[ply] = nil

hook.Add "PlayerInitialSpawn", "CFC_ErrForwarder_BucketReset", (ply) -> buckets[ply] = Config.bucketSize\GetInt!

(SetLogger, SetForwarder, SetConfig) ->
    Logger = SetLogger
    Forwarder = SetForwarder
    Config = SetConfig
