import Count from table
import TableToJSON from util

class ErrorForwarder
    new: (logger, webhooker, groomInterval) =>
        @logger = logger
        @webhooker = webhooker
        @groomInterval = groomInterval
        @queue = {}

    countQueue: => Count @queue

    queueIsEmpty: => @countQueue! == 0

    errorIsQueued: (fullError) => @queue[fullError] ~= nil

    addPlyToObject: (errorStruct, ply) =>
        playerStruct =
            playerName: ply\Name!,
            playerSteamID: ply\SteamID!

        errorStruct.player = playerStruct

        errorStruct

    queueError: (isRuntime, fullError, sourceFile, sourceLine, errorString, stack, ply) =>
        count = 1
        occurredAt = os.time!
        isClientside = ply ~= nil

        newError =
            :count
            :errorString,
            :fullError,
            :isRuntime,
            :occurredAt,
            :sourceFile,
            :sourceLine,
            :stack,
            :isClientside

        if isClientside
            newError = @addPlyToObject newError, ply

        @logger\info "Inserting error into queue: '#{fullError}'"

        @queue[fullError] = newError

    unqueueError: (fullError) =>
        @queue[fullError] = nil

    incrementError: (fullError) =>
        @queue[fullError]["count"] += 1
        @queue[fullError]["occurredAt"] = os.time!

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
        @logger\info "Received Serverside Lua Error: #{errorString}"
        @logErrorInfo isRuntime, fullError, sourceFile, sourceLine, errorString, stack

        @receiveError isRuntime, fullError, sourceFile, sourceLine, errorString, stack

    receiveCLError: (ply, fullError, sourceFile, sourceLine, errorString, stack) =>
        @logger\info "Received Clientside Lua Error for #{ply\SteamID!} (#{ply\Name!}): #{errorString}"
        @logErrorInfo nil, fullError, sourceFile, sourceLine, errorString, stack

        @receiveError isRuntime, fullError, sourceFile, sourceLine, errorString, stack, ply

    generateJSONStruct: (errorStruct) =>
        errorObject["reportInterval"] = @groomInterval

        errorJSON = TableToJSON errorStruct

        { json: errorJSON }

    forwardError: (errorStruct, onSuccess, onFailure) =>
        @logger\info "Sending error object.."
        data = @generateJSONStruct errorStruct

        @webhooker\send "forward-errors", data, onSuccess, onFailure

    forwardErrors: =>
        for errorString, errorData in pairs @queue
            @logger\debug "Processing queued error: #{errorString}"

            success = (message) -> @onSuccess errorString, message
            failure = (failure) -> @onFailure errorString, failure

            @forwardError errorData, success, failure

    groomQueue: =>
        return if @queueIsEmpty!

        @logger\info "Grooming Error Queue of size #{@countQueue!}"

        @forwardErrors!

    onSuccess: (fullError, message) =>
        @logger\info "Successfully sent error: #{fullError}"
        @unqueueError fullError

    onFailure: (fullError, failure) =>
        @logger\error "Failed to send error!\n#{failure}"
        @unqueueError fullError

