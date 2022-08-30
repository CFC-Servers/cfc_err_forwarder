import Count from table

osTime = os.time
rawset = rawset
rawget = rawget
istable = istable

removeCyclic = (tbl, found={}) ->
    return if found[tbl]
    found[tbl] = true

    for k, v in pairs tbl
        continue unless istable v

        if found[v]
            print "Found cyclic table, key: #{k} | value: #{v} | table: #{tbl}"
            tbl[k] = nil
        else
            removeCyclic v, found

stripStack = (tbl) ->
    for _, stackObj in pairs tbl
        stackObj.upvalues = nil
        stackObj.activelines = nil

saveLocals = (stack) ->
    for _, stackObj in pairs tbl
        newLocals = {}

        for name, value in pairs stackObj.locals
            if istable value
                newTbl = {}

                count = 0
                for key, val in pairs value
                    break if count >= 5
                    newTbl[key] = tostring val
                    count += 1

                newLocals[name] = table.ToString newTbl
            else
                newLocals[name] = tostring value

            newLocal = newLocals[name]
            if #newLocal > 50
                newLocals[name] = "#{string.Left newLocal, 47}..."

        stackObj.locals = newLocals

return class ErrorForwarder
    new: (logger, discord, config) =>
        @logger = logger
        @discord = discord
        @config = config
        @queue = {}

    countQueue: => Count @queue

    errorIsQueued: (fullError) => rawget(@queue, fullError) ~= nil

    addPlyToObject: (errorStruct, ply) =>
        rawset errorStruct, "player", {
            playerName: ply\Name!,
            playerSteamID: ply\SteamID!
        }

        errorStruct

    queueError: (isRuntime, fullError, sourceFile, sourceLine, errorString, stack, ply) =>
        count = 1
        occurredAt = osTime!
        isClientside = ply ~= nil
        saveLocals stack

        newError = {
            :count
            :errorString
            :fullError
            :isRuntime
            :occurredAt
            :sourceFile
            :sourceLine
            :stack
            :isClientside
            reportInterval: @config.groomInterval\GetInt!
        }

        if isClientside
            newError = @addPlyToObject newError, ply

        @logger\info "Inserting error into queue: '#{fullError}'"

        rawset @queue, fullError, newError

    unqueueError: (fullError) =>
        thisErr = rawget @queue, fullError

        if thisErr
            for k in pairs thisErr
                rawset thisErr, k, nil

        rawset @queue, fullError, nil

    incrementError: (fullError) =>
        thisErr = rawget @queue, fullError
        count = rawget thisErr, "count"

        rawset thisErr, "count", count + 1
        rawset thisErr, "occurredAt", osTime!

    receiveError: (isRuntime, fullError, sourceFile, sourceLine, errorString, stack, ply) =>
        if @errorIsQueued fullError
            return @incrementError fullError

        @queueError isRuntime, fullError, sourceFile, sourceLine, errorString, stack, ply

    logErrorInfo: (isRuntime, fullError, sourceFile, sourceLine, errorString, stack) =>
        debug = @logger\info

        debug "Is Runtime: #{isRuntime}"
        debug "Full Error: #{fullError}"
        debug "Source File: #{sourceFile}"
        debug "Source Line: #{sourceLine}"
        debug "Error String: #{errorString}"

    receiveSVError: (isRuntime, fullError, sourceFile, sourceLine, errorString, stack) =>
        @logger\info "Received Serverside Lua Error: #{errorString}"
        @logErrorInfo isRuntime, fullError, sourceFile, sourceLine, errorString, stack

        @receiveError isRuntime, fullError, sourceFile, sourceLine, errorString, stack

    receiveCLError: (ply, fullError, sourceFile, sourceLine, errorString, stack) =>
        return unless ply and ply\IsPlayer!
        return unless @config.clientEnabled\GetBool!

        @logger\info "Received Clientside Lua Error for #{ply\SteamID!} (#{ply\Name!}): #{errorString}"
        @logErrorInfo true, fullError, sourceFile, sourceLine, errorString, stack

        @receiveError true, fullError, sourceFile, sourceLine, errorString, stack, ply

    cleanStruct: (errorStruct) =>
        stripStack errorStruct.stack
        return errorStruct

    forwardError: (errorStruct, onSuccess, onFailure) =>
        @logger\info "Sending error object.."
        data = @cleanStruct errorStruct

        self.discord data, onSuccess, onFailure

    forwardErrors: =>
        for errorString, errorData in pairs @queue
            @logger\debug "Processing queued error: #{errorString}"

            onSuccess = -> @onSuccess errorString
            onFailure = (failure) -> @onFailure errorString, failure

            success, err = pcall ->
                @forwardError errorData, onSuccess, onFailure

            continue if success

            onFailure err

    groomQueue: =>
        count = @countQueue!
        return if count == 0

        @logger\info "Grooming Error Queue of size: #{count}"
        @forwardErrors!

    onSuccess: (fullError) =>
        @logger\info "Successfully sent error", fullError

        @unqueueError fullError

    onFailure: (fullError, failure) =>
        @logger\error "Failed to send error!", failure
        @unqueueError fullError
