(val) ->
    if isstring val
        val = "\"#{val}\""

    val
