class ErrorForwarder
    new: (logger, webhooker_interface) =>
        @logger = logger
        @webhooker_interface = webhooker_interface
        @groom_interval = 60
        @queue = {}

        groom = => self\groom_queue

        timer_name = "CFC_ErrorForwarderQueue"
        timer.Remove timer_name
        timer.Create timer_name, groom_interval, 0, groom

    count_queue: =>
        table.Count @queue

    queue_is_empty: => @count_queue! == 0

    error_is_queued: (error_string) => @queue[error_string] != nil

    add_error_to_queue: (is_runtime, full_error, source_file, source_line, error_string, stack) =>
        occurred_at = os.time!
        count = 1

        new_error = {
            :count
            :error_string,
            :full_error,
            :is_runtime,
            :occurred_at,
            :source_file,
            :source_line,
            :stack,
        }

        @logger\info "Inserting error into queue: #{error_string}"

        @queue[error_string] = new_error

    remove_error_from_queue: (error_string) =>
        @queue[error_string] = nil

    increment_existing_error: (error_string) =>
        @queue[error_string]["count"] += 1
        @queue[error_string]["occurred_at"] = os.time!

    receive_lua_error: (is_runtime, full_error, source_file, source_line, error_string, stack) =>
        @logger\debug "Received Lua Error: #{error_string}"

        if @error_is_queued error_string
            return @increment_existing_error error_string

        @add_error_to_queue is_runtime, full_error, source_file, source_line, error_string, stack

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

