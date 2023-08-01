import Count from table

osTime = os.time
rawset = rawset
rawget = rawget
istable = istable

pretty = include "cfc_err_forwarder/formatter/pretty_values.lua"

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

stringTable = (tbl) ->
    oneline = table.Count(tbl) == 1

    str = "{"
    str ..= "\n" unless oneline

    count = 0
    for k, v in pairs tbl
        break if count >= 5

        str ..= "  #{k} = #{pretty v}"
        str ..= oneline and " " or "\n"

        count += 1

    str ..= "}"

    str

saveLocals = (stack) ->
    for _, stackObj in pairs stack
        locals = stackObj.locals
        continue unless locals

        newLocals = {}
        for name, value in pairs locals
            if istable value
                newLocals[name] = stringTable value
            else
                newLocals[name] = pretty value

                newLocal = newLocals[name]
                if #newLocal > 125
                    newLocals[name] = "#{string.Left newLocal, 122}..."

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
        locals = saveLocals stack

        local plyName
        local plySteamID
        local branch
        if ply
            plyName = ply\Nick!
            plySteamID = ply\SteamID!
            branch = ply.CFC_ErrorForwarder_CLBranch or "MISSING"
        else
            branch = BRANCH

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
            :ply
            :plyName
            :plySteamID
            :branch
            reportInterval: @config.groomInterval\GetInt!
        }

        if isClientside
            newError = @addPlyToObject newError, ply

        @logger\debug "Inserting error into queue: '#{fullError}'"

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
        debug = @logger\debug

        debug "Is Runtime: #{isRuntime}"
        debug "Full Error: #{fullError}"
        debug "Source File: #{sourceFile}"
        debug "Source Line: #{sourceLine}"
        debug "Error String: #{errorString}"

    receiveSVError: (isRuntime, fullError, sourceFile, sourceLine, errorString, stack) =>
        @logger\debug "Received Serverside Lua Error: #{errorString}"
        @logErrorInfo isRuntime, fullError, sourceFile, sourceLine, errorString, stack

        @receiveError isRuntime, fullError, sourceFile, sourceLine, errorString, stack

    receiveCLError: (ply, fullError, sourceFile, sourceLine, errorString, stack) =>
        return unless ply and ply\IsPlayer!
        return unless @config.clientEnabled\GetBool!

        @logger\debug "Received Clientside Lua Error for #{ply\SteamID!} (#{ply\Name!}): #{errorString}"
        @logErrorInfo true, fullError, sourceFile, sourceLine, errorString, stack

        @receiveError true, fullError, sourceFile, sourceLine, errorString, stack, ply

    -- TODO: Remove this stupid thing andc all stripStack directly
    cleanStruct: (errorStruct) =>
        stripStack errorStruct.stack
        return errorStruct

    forwardError: (errorStruct, onSuccess, onFailure) =>
        @logger\debug "Sending error object.."
        self.discord errorStruct, onSuccess, onFailure

    forwardErrors: =>
        for errorString, data in pairs @queue
            @logger\debug "Processing queued error: #{errorString}"

            errorData = @cleanStruct data

            onSuccess = -> @onSuccess errorString
            onFailure = (failure) -> @onFailure errorString, failure, errorData

            success, err = pcall ->
                @forwardError errorData, onSuccess, onFailure

            continue if success

            onFailure err

    groomQueue: =>
        count = @countQueue!
        return if count == 0

        @logger\debug "Grooming Error Queue of size: #{count}"
        @forwardErrors!

    onSuccess: (fullError) =>
        @logger\debug "Successfully sent error", fullError

        @unqueueError fullError

    onFailure: (fullError, failure, errorData) =>
        @logger\error "Failed to send error!", failure
        @unqueueError fullError
        print util.TableToJSON failedErrorData: errorData

