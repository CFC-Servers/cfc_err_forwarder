import Count from table

rawset = rawset
rawget = rawget
os_time = os.time

:stripStack, :saveLocals = include "cfc_err_forwarder/helpers.lua"
discordBuilder = include "cfc_err_forwarder/discord_interface.lua"

class ErrorForwarder
    new: (logger, config) =>
        @queue = {}
        @config = config
        @logger = logger
        @discord = discordBuilder logger, config
        @timerName = "CFC_ErrorForwarderQueue"

        @startTimer!

    startTimer: () =>
        timer.Create @timerName, @config.dedupeDuration\GetInt! or 60, 0, ->
            ProtectedCall @\groomQueue

    adjustTimer: (interval) =>
        timer.Adjust @timerName, tonumber interval

    errorIsQueued: (fullError) => rawget(@queue, fullError) ~= nil

    queueError: (isRuntime, fullError, sourceFile, sourceLine, errorString, stack, ply) =>
        count = 1
        occurredAt = os_time!

        saveLocals stack
        stripStack stack

        isClientside = ply ~= nil
        hasPly = isClientside and ply\IsValid!

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
            :hasPly
        }

        if hasPly
            newError.plyName = ply\Nick!
            newError.plySteamID = ply\SteamID!

        @logger\debug "Inserting error into queue: '#{fullError}'"

        rawset @queue, fullError, newError

    incrementError: (fullError) =>
        with rawget @queue, fullError
            .count += 1
            .occurredAt = os_time!

    receiveError: (isRuntime, fullError, sourceFile, sourceLine, errorString, stack, ply) =>
        if @errorIsQueued fullError
            return @incrementError fullError

        @queueError isRuntime, fullError, sourceFile, sourceLine, errorString, stack, ply
        return nil

    receiveSVError: (isRuntime, fullError, sourceFile, sourceLine, errorString, stack) =>
        @logger\debug "Received Serverside Lua Error: #{errorString}"
        @receiveError isRuntime, fullError, sourceFile, sourceLine, errorString, stack

    receiveCLError: (ply, fullError, sourceFile, sourceLine, errorString, stack) =>
        return unless ply and ply\IsPlayer!
        return unless @config.clientEnabled\GetBool!

        @logger\debug "Received Clientside Lua Error for #{ply\SteamID!} (#{ply\Name!}): #{errorString}"

        @receiveError true, fullError, sourceFile, sourceLine, errorString, stack, ply

    forwardErrors: =>
        for errorString, errorData in pairs @queue
            @logger\debug "Sending queued error to Discord: #{errorString}"
            @discord\Send errorData

        table.Empty @queue

    groomQueue: =>
        count = Count @queue
        return if count == 0

        @logger\debug "Grooming Error Queue of size: #{count}"
        @forwardErrors!


return ErrorForwarder
