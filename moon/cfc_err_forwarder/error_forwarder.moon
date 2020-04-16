import Count from table
import TableToJSON from util

class ErrorForwarder
    new: (logger, webhooker, groomInterval) =>
        @logger = logger
        @webhooker = webhooker
        @groomInterval = groomInterval
        @queue = {}

    countQueue: =>
        Count @queue

    queueIsEmpty: => @countQueue! == 0

    errorIsQueued: (errorString) => @queue[errorString] ~= nil

    addPlyToObject: (errorStruct, ply) =>
        playerStruct = {
            playerName: ply\Name!,
            playerSteamID: ply\SteamID!
        }

        errorStruct.player = playerStruct
        errorStruct["player"] = playerStruct

        errorStruct

    queueError: (isRuntime, fullError, sourceFile, sourceLine, errorString, stack, ply = nil) =>
        count = 1
        occurredAt = os.time!
        isClientside = ply ~= nil

        new_error =
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
            new_error = @addPlyToObject(new_error, ply)

        @logger\info "Inserting error into queue: #{errorString}"

        @queue[errorString] = new_error

    unqueueError: (errorString) =>
        @queue[errorString] = nil

    increment_existing_error: (errorString) =>
        @queue[errorString]["count"] += 1
        @queue[errorString]["occurredAt"] = os.time!

    receiveError: (isRuntime, fullError, sourceFile, sourceLine, errorString, stack, ply = nil) =>
        if @errorIsQueued errorString
            return @increment_existing_error errorString

        @queueError isRuntime, fullError, sourceFile, sourceLine, errorString, stack, ply

    receiveSVError: (isRuntime, fullError, sourceFile, sourceLine, errorString, stack) =>
        @logger\debug "Received Serverside Lua Error: #{errorString}"
        @receiveError isRuntime, fullError, sourceFile, sourceLine, error_String, stack

    receiveCLError: (ply, fullError, sourceFile, sourceLine, errorString, stack) =>
        @logger\debug "Received Clientside Lua Error for #{ply\SteamID!} (#{ply\Name!}): #{errorString}"
        @receiveError isRuntime, fullError, sourceFile, sourceLine, error_String, stack, ply

    generate_json_object: (error_object) =>
        errorObject["report_interval"] = @groomInterval

        errorJSON = TableToJSON errorObject

        { json: errorJSON }

    forward_error: (error_object, onSuccess, onFailure) =>
        @logger\info "Sending error object.."

        data = @generate_json_object error_object

        @webhooker\send "forward-errors", data, onSuccess, onFailure

    forwardErrors: =>
        for errorString, errorData in pairs @queue
            @logger\debug "Processing queued error: #{errorString}"

            success = (message) ->
                @onSuccess errorString, message

            failure = (failure) ->
                @onFailure errorString, failure

            @forward_error errorData, success, failure

    groomQueue: =>
        return if @queueIsEmpty!

        @logger\info "Grooming Error Queue of size #{@countQueue!}"

        @forwardErrors!

    onSuccess: (errorString, message) =>
        @logger\info "Successfully sent error: #{errorString}"
        @unqueueError errorString

    onFailure: (errorString, failure) =>
        @logger\error "Failed to send error!\n#{failure}"
        @unqueueError errorString

