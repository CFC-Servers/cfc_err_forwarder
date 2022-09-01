MAX_LOCALS = 8

(data) ->
    local locals
    :stack = data

    for level in *stack
        continue if locals
        continue unless level
        :locals = level

    return unless locals
    return if table.Count(locals) == 0

    out = {}
    longest = 0
    for name, value in pairs locals
        longest = #name if #name > longest
        table.insert out, {:name, :value}

    convert = (line) ->
        {:name, :value} = line
        spacing = string.rep " ", longest - #name
        "#{name} #{spacing}= #{value}"

    maxLocals = math.min MAX_LOCALS, #out
    out = [convert line for line in *out[,maxLocals]]

    table.concat out, "\n"
