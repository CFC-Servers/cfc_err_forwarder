class ErrorForwarder
    new: (logger, webhooker_interface, groom_interval) =>
        @logger = logger
        @webhooker_interface = webhooker_interface
        @groom_interval = groom_interval
        @queue = {}

    count_queue: =>
        table.Count @queue

    queue_is_empty: => @count_queue! == 0

    error_is_queued: (error_string) => @queue[error_string] != nil

    add_ply_to_object: (error_object, ply) =>
        player_obj = {
            player_name: ply\Name!,
            player_steam_id: ply\SteamID!
        }

        error_object["player"] = player_obj

        error_object

    add_error_to_queue: (is_runtime, full_error, source_file, source_line, error_string, stack, ply = nil) =>
        count = 1
        occurred_at = os.time!
        is_clientside = ply ~= nil

        new_error = {
            :count
            :error_string,
            :full_error,
            :is_runtime,
            :occurred_at,
            :source_file,
            :source_line,
            :stack,
            :is_clientside
        }

        if is_clientside
            new_error = @add_ply_to_object(new_error, ply)

        @logger\info "Inserting error into queue: #{error_string}"

        @queue[error_string] = new_error

    remove_error_from_queue: (error_string) =>
        @queue[error_string] = nil

    increment_existing_error: (error_string) =>
        @queue[error_string]["count"] += 1
        @queue[error_string]["occurred_at"] = os.time!

    receive_lua_error: (is_runtime, full_error, source_file, source_line, error_string, stack, ply = nil) =>
        if @error_is_queued error_string
            return @increment_existing_error error_string

        @add_error_to_queue is_runtime, full_error, source_file, source_line, error_string, stack, ply

    receive_sv_lua_error: (is_runtime, full_error, source_file, source_line, error_string, stack) =>
        @logger\debug "Received Serverside Lua Error: #{error_string}"
        @receive_lua_error is_runtime, full_error, source_file, source_line, error_String, stack

    receive_cl_lua_error: (ply, full_error, source_file, source_line, error_string, stack) =>
        @logger\debug "Received Clientside Lua Error for #{ply\SteamID!} (#{ply\Name!}): #{error_string}"
        @receive_lua_error is_runtime, full_error, source_file, source_line, error_String, stack, ply

    generate_json_object: (error_object) =>
        error_object["report_interval"] = @groom_interval

        error_json = util.TableToJSON error_object

        { json: error_json }

    forward_error: (error_object, on_success, on_failure) =>
        @logger\info "Sending error object.."

        data = @generate_json_object error_object

        @webhooker_interface\send "forward-errors", data, on_success, on_failure

    forward_all_errors: =>
        for error_string, error_data in pairs @queue
            @logger\debug "Processing queued error: #{error_string}"

            success = (message) ->
                @on_success error_string, message

            failure = (failure) ->
                @on_failure error_string, failure

            @forward_error error_data, success, failure

    groom_queue: =>
        if @queue_is_empty! then return

        @logger\info "Grooming Error Queue of size #{@count_queue!}"

        @forward_all_errors!

    on_success: (error_string, message) =>
        @logger\info "Successfully sent error: #{error_string}"
        @remove_error_from_queue error_string

    on_failure: (error_string, failure) =>
        @logger\error "Failed to send error!\n#{failure}"
        @remove_error_from_queue error_string

