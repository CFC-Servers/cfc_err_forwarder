pretty = include "pretty_values.lua"

(data) ->
    local locals
    :stack = data

    for level in *stack
        continue if locals
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
        "#{name} #{spacing}= #{pretty value}"

    maxLocals = math.min 5, #out
    out = [convert line for line in *out[,maxLocals]]

    table.concat out, "\n"
